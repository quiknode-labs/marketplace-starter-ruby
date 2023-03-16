# Quicknode Marketplace Starter Code - Ruby

This is a sample [QuickNode Marketplace](https://quicknode.com/marketplace) add-on built on top
of Sinatra and PostgreSQL.

It implements the 4 provisioning routes that a partner needs to [integrate with Marketplace](https://www.quicknode.com/guides/quicknode-products/marketplace/how-provisioning-works-for-marketplace-partners/), as well as the required Healthcheck route.

It also has support for:

- [RPC methods](https://www.quicknode.com/guides/quicknode-products/marketplace/how-to-create-an-rpc-add-on-for-marketplace/) via a `POST /rpc` route
- [A dashboard view](https://www.quicknode.com/guides/quicknode-products/marketplace/how-sso-works-for-marketplace-partners/) with Single Sign On using JSON Web Tokens (JWT).

## Getting Started

To install and run the application locally:

1. Clone the repository.
2. `gem install foreman`
3. `bundle`
4. Copy `.env.example` to `.env` file and fill in with the appropiate values.
5. `rake db:migrate`
6. `bin/dev`

## Routes

The application has 4 provisioning routes protected by HTTP Basic Auth:

- `POST /provision`
- `PUT /update`
- `DELETE /deactivate`
- `DELETE /deprovision`

It has a public healthcheck route that returns 200 if the service and the database is up and running:

- `GET /healthcheck`

It has a dashboard that can be accessed using Single Sign On with JSON Web Token (JWT):

- `GET /dashboard?jwt=foobar`

It has an JSON RPC route:

- `POST /rpc`

## Testing with qn-marketplace-cli

You can use the [qn-marketplace-cli](https://github.com/quiknode-labs/qn-marketplace-cli) tool to quickly test your add-on while developing it.

To obtain a basic auth string, you can use Ruby or your language of choice with your username and password, as such:

```ruby
require 'securerandom'

secret_key = SecureRandom.hex(32)

```

For the commands below, the `--basic-auth` flag is the Base64 encoding of `username:password`.
You need to make sure to replace that with your valid credentials (as defined in your `.env` file).

PUDD:

```sh
./qn-marketplace-cli pudd --base-url http://localhost:3005 --basic-auth dXNlcm5hbWU6cGFzc3dvcmQ=
```

SSO:

```sh
./qn-marketplace-cli sso --url http://localhost:3005/provision --jwt-secret jwt-secret --basic-auth dXNlcm5hbWU6cGFzc3dvcmQ=
```

RPC:

```sh
./qn-marketplace-cli rpc --url http://localhost:3005/provision --rpc-method qn_test --rpc-url http://localhost:3005/rpc  --rpc-params "[\"abc\"]" --basic-auth dXNlcm5hbWU6cGFzc3dvcmQ=
```

Healthcheck:

```sh
./qn-marketplace-cli healthcheck --url http://localhost:3005/healthcheck
```

## License

MIT
