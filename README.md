# Quicknode Marketplace Starter Code - Ruby

This is a sample [QuickNode Marketplace](https://quicknode.com/marketplace) add-on built on top
of Sinatra and PostgreSQL.

It implements the 4 provisioning routes that a partner needs to [integrate with Marketplace](https://www.quicknode.com/guides/quicknode-products/marketplace/how-provisioning-works-for-marketplace-partners/), as well as the required Healthcheck route.

It also has support for:

- [RPC methods](https://www.quicknode.com/guides/quicknode-products/marketplace/how-to-create-an-rpc-add-on-for-marketplace/) via a `POST /rpc` route
- [A dashboard view](https://www.quicknode.com/guides/quicknode-products/marketplace/how-sso-works-for-marketplace-partners/) with Single Sign On using JSON Web Tokens (JWT).


## Getting Started

To run locally:

1. `gem install foreman`
2. `bundle`
3. Copy `.env.example` to `.env` file and overwrite with correct variables for your env
4. `rake db:migrate`
5. `bin/dev`

## SSO support

if you would like to provide your own portal that quicknode customers can have access to after they have been provisioned, generate a JWT secret key locally and store it in the `.env` file as `JWT_SECRET`. For more details on the entire process, refer to the [SSO guide](https://www.quicknode.com/guides/quicknode-products/marketplace/how-sso-works-for-marketplace-partners/).

```ruby
require 'securerandom'

secret_key = SecureRandom.hex(32)

```
