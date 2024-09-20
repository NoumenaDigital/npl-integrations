# IOU Typescript Webapp

This project is a webapp that demonstrates how to integrate with the NPL engine using the IOU extension.
It is built using Typescript and React. It allows users to create, read and perform actions of IOUs.

## Maven generator

The selected maven generator for typescript is 'typescript-axios'.
It solves a few compilation and setup errors.

## Authentication in the API service

The Keycloak service is used for authentication.
The keycloak service is configured in the `src/KeycloakProvider.tsx` file and is used to authenticate the user and get the access token.
The access token is then used to authenticate the API service in the `src/services/BaseService.tsx` and attached as header to http requests.

```typescript
    private withAuthorizationHeader = () => {
        return { headers: { Authorization: `Bearer ${this.keycloak.token}` } }
    }
```

## API service

The API service is implemented in the `src/services/BaseService.tsx` file and is used to interact with the NPL engine.
It relies on the generated sources from the NPL engine to make requests to the engine.

```typescript
    public getIouList: () => Promise<Iou[]> = async () =>
    this.api
        .getIouList(
            undefined,
            undefined,
            undefined,
            this.withAuthorizationHeader()
        )
        .then((it) => it.data.items)
```

## State streaming

The state streaming is implemented in the `src/services/BaseService.tsx` file and is used to stream the state of IOU protocol instances.
The demonstration implementation refreshes the data when the state of the IOU protocol instance changes.

From the `src/services/BaseService.tsx` file:
```typescript
    public useStateStream = (requestRefresh: () => void) => {
        // ...
    }
```

And used in the `src/components/HomePage.tsx` file:
```typescript
    const active = useStateStream(() => getIouList().then((it) => setIouList(it)))

    useEffect(() => {
        if (!createIouDialogOpen && !repayIouDialogOpen.open) {
            getIouList().then((it) => setIouList(it))
        }
    }, [active])
```
