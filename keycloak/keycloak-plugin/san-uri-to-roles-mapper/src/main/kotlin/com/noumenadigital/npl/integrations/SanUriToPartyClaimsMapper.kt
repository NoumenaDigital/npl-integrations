package com.noumenadigital.npl.integrations

import org.keycloak.models.ClientSessionContext
import org.keycloak.models.KeycloakSession
import org.keycloak.models.ProtocolMapperModel
import org.keycloak.models.UserSessionModel
import org.keycloak.protocol.ProtocolMapper
import org.keycloak.protocol.oidc.mappers.AbstractOIDCProtocolMapper
import org.keycloak.protocol.oidc.mappers.OIDCAccessTokenMapper
import org.keycloak.provider.ProviderConfigProperty
import org.keycloak.provider.ProviderFactory
import org.keycloak.representations.AccessToken

class SanUriToPartyClaimsMapper :
    AbstractOIDCProtocolMapper(),
    OIDCAccessTokenMapper {
    companion object {
        const val PROVIDER_ID = "san-uri-to-roles"
        private const val ATTRIBUTE_SAN_URI = "x509.san.uri"
        private const val ATTRIBUTE_SERIAL_ID = "x509.serialId"
        private const val SAN_URI_EMAIL = "uri:role://email"
        private const val SAN_URI_PREFERRED_USERNAME = "uri:role://preferred_username"
    }

    override fun getDisplayCategory(): String = "Token Mapper"

    override fun getDisplayType(): String = "SAN URIs → Required NPL party claims"

    override fun getHelpText(): String = "Reads client attributes (e.g. x509.san.uri) and writes to required NPL party claim fields"

    override fun getId(): String = PROVIDER_ID

    override fun getConfigProperties(): MutableList<ProviderConfigProperty> = mutableListOf()

    override fun transformAccessToken(
        token: AccessToken,
        mappingModel: ProtocolMapperModel,
        session: KeycloakSession,
        userSession: UserSessionModel?,
        clientSessionCtx: ClientSessionContext?,
    ): AccessToken {
        val raw = session.getAttribute(ATTRIBUTE_SAN_URI, String::class.java) ?: return token
        val values = raw.split(Regex("[\\s,]+")).filter { it.isNotBlank() }
        token.otherClaims["cert_sans"] = values

        val emailUri = values.firstOrNull { it.startsWith(SAN_URI_EMAIL) }
        if (emailUri != null) {
            val emailValue = emailUri.removePrefix(SAN_URI_EMAIL)
            token.otherClaims["email"] = emailValue
        }

        val preferredUsernameUri = values.firstOrNull { it.startsWith(SAN_URI_PREFERRED_USERNAME) }
        if (preferredUsernameUri != null) {
            val preferredUsernameValue = preferredUsernameUri.removePrefix(SAN_URI_PREFERRED_USERNAME)
            token.otherClaims["preferred_username"] = preferredUsernameValue
        }

        val serialId = session.getAttribute(ATTRIBUTE_SERIAL_ID, String::class.java)
        if (!serialId.isNullOrBlank()) {
            token.otherClaims["cert_serialId"] = serialId
        }

        return token
    }

    class Factory : ProviderFactory<ProtocolMapper> {
        override fun create(session: KeycloakSession): ProtocolMapper = SanUriToPartyClaimsMapper()

        override fun getId(): String = PROVIDER_ID

        override fun init(config: org.keycloak.Config.Scope?) {}

        override fun postInit(factory: org.keycloak.models.KeycloakSessionFactory?) {}

        override fun close() {}
    }
}
