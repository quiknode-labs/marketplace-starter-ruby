# Ruby Starter code

This is a sample QuickNode Marketplace application built on top
of [Sinatra](https://sinatrarb.com/) and [postgres](https://www.postgresql.org/).

It implements the 4 routes that a partner needs to [integrate with Marketplace](https://www.notion.so/quicknode/Marketplace-Integration-Overview-f272bbbfac364cbdae70566984de77bf):

- `POST /provision`
- `PUT /update`
- `DELETE /deactivate`
- `DELETE /deprovision`

It uses postgres to store/update provisioned endpoints.

It also has additional routes for optional features:

- `POST /rpc` - JSON RPC proxy
- `GET /dash` - shows info about the endpoint that was provisioned.
- `GET /api/:id` - a JSON API returning the data you want to fetch.

## Installation

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
