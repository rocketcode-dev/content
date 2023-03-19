# Moving APIs from the v5c to API Gateway

Thomas D Wilkinson, IBM Hybrid Cloud Integration, October 2021

One of the earliest choices API Connect users have to make is whether to set up a gateway V5 Compatibility mode (v5c) or the native API Gateway. All else being equal, the obvious choice is to use the API Gateway; the performance benefits are astounding. All new work should use the API Gateway. Unfortunately, sometimes this is not practical in the short term. APIs may be moved from an existing Version 5 installation, either by migration or reuse, and time constraints may make it difficult to move the existing APIs at once.

The cloud admins have to make a choice: complete a v5 migration quickly by using v5c, or force everyone to migrate to v10 on their imposed schedule? When there are too many teams providing APIs, each with their own schedule constraints, coordinating a move is difficult. Because of this, admins often hold their noses and select V5 Compatibility mode.

The good news is that they aren't stuck with it. We can provide both gateway types and allow API developers to migrate their APIs on their own time.

## Prerequisites

This document assumes that API Connect has been migrated from V5 to V10 (or V2018) using V5 Compatibility Mode, API Connect is live in production, and multiple teams contribute APIs. It also assumes consumers are already using the APIs and would prefer not to have to change their own code to accommodate platform changes.

# Migration process overview

Each phase in this process is handled by different people. First the cloud admins set up the new gateway, then the load balancer admins set up the paths or error handlings, then finally the API developers start moving their products to the new gateway.

## A Tale of Two Gateways

The first step is to set up the API Gateway on each DataPower machine. A DataPower host can run multiple gateways, as long as they are in separate domains and use different interfaces or ports. 

1. Take a note of the existing gateway configuration, including interfaces and ports used for the gateway, the gateway director, and peering. For example, if you're using the defaults, you would be occupying ports 3000, 9443, 16380, and 26380. We must avoid using these ports for the API Gateway.
2. Create a new domain on DataPower, and [set up the gateway](https://www.ibm.com/docs/en/api-connect/10.0.1.x?topic=connect-configuring-datapower-api-gateway), being careful to avoid using the same ports as the existing v5c Gateway.
3. In the Cloud Manager UI, [register the new gateway service](https://www.ibm.com/docs/en/api-connect/10.0.1.x?topic=topology-registering-gateway-service). You may register multiple gateway services in API Connect. For the API endpoint base, use the same base URL as the existing v5c gateway (really!).

## Load Balancer configuration

There are three alternatives to routing requests so they can find the correct gateway, each have different benefits and requirements.

All of these routing schemes are transparent to the consumer, and all but one of 
### Path-based routing

* Zero performance overhead for all APIs
* Zero latency cost for all APIs
* Highest maintenance effort
* Adds friction to migration effort, and teams creating new APIs might be tempted to use the old gateway to avoid having to make requests for path.
* Does not permit versions on both gateways

If the load balancer is capable of path-based routing, maintain a list of base paths for APIs that have been migrated. Paths known to have been migrated are routed to the API Gateway, and others are routed to the v5c Gateway. When the developers are ready to cut over, ask them to request their API base paths be rerouted to the new API Gateway instead of the V5C Gateway.

Many customers do prefer to do it this way because it offers the best performance and lowest latency for APIs.

Unfortunately, this is usually an error-prone manual processes, especially if there are a large number of end points. Developers may also be discouraged to move if they must depend on another team to configure the load balancers when they are ready to move. This friction may discourage developers to migrate their work.

Also, path-based routers are unable to account for API versions. A consumer subscribed to an old version of an API on the old gateway will lose access to the API until they update their subscription.

### Testing error codes and rerouting 404s and 401s

* Affects performance
* Increases latency for un-migrated APIs
* Lowest maintenance effort
* Adds zero friction to migration effort
* Allows versions on both gateways

If the load balancer can respond to errors, it can send all requests to the API Gateway first. If the API Gateway responds with a 404 or a 401 error, then resend the request to the v5c gateway. Do not resend requests if other error types, like 400 or 500, are returned.

This is the easiest, most frictionless means to move APIs from the v5c to the API Gateway. It also gives the teams freedom to back out of a migration if there's a problem. This scheme also keeps old versions on the old gateway accessible if the consumer hasn't yet updated their subscriptions to use the new version.

The drawback is that the API Gateway will have to process a lot of 404 and 401 errors. Initially, all requests will produce a 404 error. This is a burden on the gateway, the API Gateway's logs will be dominated by 404 errors unless they are suppressed, and it adds latency to APIs still in the v5c gateway.

> Ideally, this solution should be used if nearly all developers intend to migrate their work quickly.

### Intermediate API

* High performance overhead
* Increases latency of all APIs
* Low maintenance effort
* Adds zero friction to migration effort
* Allows versions on both gateways

If the load balancer has no capabilities to respond to errors or perform path-based routing, an intermediate API could be created to do either. Set up an unsecured API in a separate catalog, published on the API Gateway, and send all API requests through it. Then this API forwards the request to the appropriate gateway.

This algorithm adds latency to all API requests, even after they've been migrated, and should not be a permanent solution. However, it is a quick way to set up routing between Gateways and does not much assistance from the load balancer team.

> This solution should only be used if 100% of APIs will be migrated before a certain deadline so this intermediate API can be removed.

### Combining Methods

* Low performance overhead
* Increases latency for low-usage un-migrated APIs
* Some maintenance effort
* Adds friction to migrations of only selected high-usage APIs
* Allows versions on both gateways

This configuration assumes the gateway can do both path-based routing and respond to error codes.

If there are a small number of heavily-used performance-critical APIs and a large number of little-used and less critical APIs, one could use path-based routing to route the most heavily-used v5c APIs to the v5c gateway without checking for a 404 or a 401 error first. 

This method is the best of manual path mapping and error code testing in that you get most of the performance benefits of path-based routing at less administrative burden. It also makes the API Gateway the default route, eliminating the temptation to write new APIs for the v5c Gateway.

However, there will still be nuisance 404 logs in the API Gateway and the host heavily-used v5c APIs still have to request load balancer paths changes to move to the API gateway.

> This solution is ideal if your catalog is burdened with both high traffic and many API products managed by several teams.

### Other methods

There are meny other methods to handle routing between two different gateways. The list above is not exhaustive. Some more examples:
* The load balancer sends all API traffic to the API gateway, and anything that isn't ported, have a shadow API on the API Gateway that invokes into the v5c gateway
* Load balancer sends all traffic to a web service on the gateway that routes traffic to the correct gateway based on path

## Migrating the APIs on the developer's schedule

In the API Manager UI, select the catalogs you would like to eventually move to API Gateway and, under Catalog Settings → Gateway Services, add the API Gateway. Catalogs can publish to multiple gateways and they don't even have to be the same type.

Once this is completed, developers can move to the new Gateway.

First migrate the product. Each product should have its gateway setting changed to `datapower-api-gateway`

```yaml
gateways:
  - datapower-api-gateway
```

Edit the API and view the swagger. First copy and past the `assembly` section of the API swagger into your favorite text editor for reference. Then change the `gateway` setting to `datapower-api-gateway` 

Once this is done, the API Assembly will complain that none of the policies are valid. Most policies have a v10 equivalent that has the exact same configuration. Usually, just changing the `version` of each policy to `2.0.0` is sufficient. If not, you'll have to replace the policy by hand using the assembly editor.

Once the API is migrated, publish it to an API Gateway and test it.

# Summary

This migration strategy, and all the load balancer schemes, provide a seamless experience for the API consumer. All they see is a version update and it's time to move a subscription. It also allows teams to migrate incrementally, and with each move a performance gain is realized.

Ideally, however, the migration should eventually come to an end, so nobody needs to maintain a scaffolding of two gateways and a complex load balancer configuration forever. There should be a deadline, the scaffolding removed, and only the one true gateway remains.
