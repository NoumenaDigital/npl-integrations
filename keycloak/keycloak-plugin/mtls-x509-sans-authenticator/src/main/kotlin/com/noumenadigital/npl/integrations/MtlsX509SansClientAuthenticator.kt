package com.noumenadigital.npl.integrations

import jakarta.ws.rs.core.Response
import org.jboss.logging.Logger
import org.keycloak.OAuth2Constants
import org.keycloak.authentication.AuthenticationFlowError
import org.keycloak.authentication.ClientAuthenticationFlowContext
import org.keycloak.authentication.authenticators.client.AbstractClientAuthenticator
import org.keycloak.authentication.authenticators.client.ClientAuthUtil
import org.keycloak.models.AuthenticationExecutionModel
import org.keycloak.models.ClientModel
import org.keycloak.protocol.oidc.OIDCLoginProtocol
import org.keycloak.provider.ProviderConfigProperty
import org.keycloak.services.x509.X509ClientCertificateLookup
import org.keycloak.utils.MediaType
import java.security.cert.X509Certificate

class MtlsX509SansClientAuthenticator : AbstractClientAuthenticator() {
    companion object {
        const val PROVIDER_ID = "mtls-x509-sans"
        private const val ATTRIBUTE_SAN_URI = "x509.san.uri"
        private const val ATTRIBUTE_SERIAL_ID = "x509.serialId"
        private const val ATTR_SUBJECT_DN_REGEX = "x509.subjectdn"
    }

    private val logger = Logger.getLogger(MtlsX509SansClientAuthenticator::class.java)

    override fun authenticateClient(context: ClientAuthenticationFlowContext) {
        val provider = context.session.getProvider(X509ClientCertificateLookup::class.java)
        if (provider == null) {
            logger.errorv(
                "\"{0}\" Spi is not available, did you fmanageret to update the configuration?",
                X509ClientCertificateLookup::class.java,
            )
            return
        }

        val certs: Array<X509Certificate> =
            (
                provider.getCertificateChain(context.httpRequest)
                    ?: emptyArray()
            ) as Array<X509Certificate>

        try {
            val headers = context.httpRequest.httpHeaders
            val mediaType = headers.mediaType
            val hasForm = mediaType != null && mediaType.isCompatible(MediaType.APPLICATION_FORM_URLENCODED_TYPE)
            val formData = if (hasForm) context.httpRequest.decodedFormParameters else null
            val queryParams = context.session.context.uri.queryParameters

            val clientId =
                formData?.getFirst(OAuth2Constants.CLIENT_ID)
                    ?: queryParams?.getFirst(OAuth2Constants.CLIENT_ID)
                    ?: context.session.getAttribute("client_id", String::class.java)

            if (clientId.isNullOrBlank()) {
                context.challenge(
                    ClientAuthUtil
                        .errorResponse(
                            Response.Status.BAD_REQUEST.statusCode,
                            "invalid_client",
                            "Missing client_id",
                        ),
                )
                return
            }

            val client = context.realm.getClientByClientId(clientId)
            if (client == null) {
                context.failure(AuthenticationFlowError.CLIENT_NOT_FOUND)
                return
            }
            context.event.client(clientId)
            context.client = client

            if (!client.isEnabled) {
                context.failure(AuthenticationFlowError.CLIENT_DISABLED, null)
                return
            }

            if (certs.isEmpty()) {
                val rsp =
                    Response
                        .status(Response.Status.UNAUTHORIZED)
                        .entity("No client certificate presented")
                        .build()
                context.challenge(rsp)
                context.failure(AuthenticationFlowError.INVALID_CLIENT_CREDENTIALS)
                return
            }

            val subjectDnRegex = client.getAttribute(ATTR_SUBJECT_DN_REGEX)
            if (subjectDnRegex == null || subjectDnRegex.isEmpty()) {
                context.failure(AuthenticationFlowError.CLIENT_CREDENTIALS_SETUP_REQUIRED)
                return
            }

            val cert = certs.first()

            val expectedRegex: String? = client.getAttribute(ATTR_SUBJECT_DN_REGEX)
            if (!expectedRegex.isNullOrBlank()) {
                val subjectDn = cert.subjectX500Principal.name
                if (!Regex(expectedRegex).containsMatchIn(subjectDn)) {
                    context.failure(AuthenticationFlowError.INVALID_CLIENT_CREDENTIALS)
                    return
                }
            }

            val uris = extractSans(cert)

            if (uris.isNotEmpty()) {
                context.session.setAttribute(ATTRIBUTE_SAN_URI, uris.joinToString(" "))
            }

            val serialHex = cert.serialNumber.toString(16)
            context.session.setAttribute(ATTRIBUTE_SERIAL_ID, serialHex)

            context.success()
        } catch (e: Exception) {
            logger.errorf("[X509ClientCertificateAuthenticator:authenticate] Exception: %s", e.stackTrace.joinToString("\n"))
            context.attempted()
            return
        }
    }

    override fun close() {
    }

    override fun getId(): String = PROVIDER_ID

    override fun getDisplayType(): String = "mTLS X.509 SANs"

    override fun isConfigurable(): Boolean = true

    override fun getAdapterConfiguration(client: ClientModel?): Map<String?, Any?> = emptyMap()

    override fun getProtocolAuthenticatorMethods(loginProtocol: String?): Set<String> =
        if (loginProtocol == OIDCLoginProtocol.LOGIN_PROTOCOL) {
            setOf(OIDCLoginProtocol.TLS_CLIENT_AUTH)
        } else {
            emptySet()
        }

    override fun getRequirementChoices(): Array<AuthenticationExecutionModel.Requirement> =
        arrayOf(
            AuthenticationExecutionModel.Requirement.REQUIRED,
            AuthenticationExecutionModel.Requirement.DISABLED,
        )

    override fun getHelpText(): String =
        "Authenticates client via mTLS and exposes certificate SANs as session attributes."

    override fun getConfigProperties(): List<ProviderConfigProperty> = emptyList()

    override fun getConfigPropertiesPerClient(): List<ProviderConfigProperty> {
        val props = mutableListOf<ProviderConfigProperty>()

        val subjectDnRegex = ProviderConfigProperty()
        subjectDnRegex.name = ATTR_SUBJECT_DN_REGEX
        subjectDnRegex.label = "Subject DN Regex"
        subjectDnRegex.type = ProviderConfigProperty.STRING_TYPE
        subjectDnRegex.helpText = "Regex pattern to validate the certificate Subject DN"
        props.add(subjectDnRegex)

        return props
    }

    override fun order(): Int = -100

    private data class Sans(
        val entries: List<List<*>>,
    ) {
        fun byType(tag: Int): List<String> =
            entries
                .filter { it.size >= 2 && (it[0] as? Number)?.toInt() == tag }
                .mapNotNull { it[1]?.toString() }
    }

    private fun safeSans(cert: X509Certificate): Sans =
        try {
            @Suppress("UNCHECKED_CAST")
            val col = cert.subjectAlternativeNames ?: emptyList()
            Sans(col.toList())
        } catch (_: Throwable) {
            Sans(emptyList())
        }

    private fun extractSans(cert: X509Certificate): List<String> {
        val sans = safeSans(cert)
        val uris = sans.byType(6) // URI: tag=6
        return uris
    }
}
