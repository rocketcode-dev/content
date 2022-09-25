# Things every API Connect installation should have

The items in this list will make an API Connect installation more stable, more usable, and more professional.

For system requirements, consult the [IBM Software Product Compatibility Report](https://www.ibm.com/software/reports/compatibility/clarity/index.html) for your version of API Connect.

## NTP Services Configured

The clocks on all nodes must be in sync. A lot of weird problems can happen if they drift apart.

This is particularly problematic with OVA installations. By default, the API Connect appliances use Ubuntu's NTP services, but many API Connect installations do not have access to the internet, and, thus, cannot reach Ubuntu's NTP service. It doesn't take long for the node's locks to drift out of sync, even if they are running on the same VMWare host. On new installations, you may provide an extra values file to configure NTP, but on existing installations, [you must configure timesyncd by hand](/article/ntp-on-api-connect).

## Notification Templates

What would you do if you received a call, "Good morning! I am Georgina from Ajax Pontiac Buick GMC with an update about the extended service plan you purchased on your 2017 GMC Yukon Denali." Assuming that is your actual vehicle and dealer, you might pay attention. Now, what if the same person called, "Hi, I have some urgent information about your car's extended warrantee." You hung up already.

This is what an invitation looks like to join the developer portal:

```text
Hello,

The administrator for the {{catalog}} developer portal has invited
you to create an API consumer organization. A consumer organization
allows you and your team to access APIs and register client apps.

To continue, please use the link below:

{{{activationLink}}}
```

It reads a lot like the extended warrantee call. Replace these notifications with branded messages and specific information. Add your company logo. Instead of "the administrator", name the actual administration team. Add a link to the admin team's intranet site. All of these things not only communicate that these notifications are important and intentional and they come from you. They also put a professional face on what is, for most of your users, their first interaction with API Connect.

## Health-check Endpoints

Every gateway service should have a health check endpoint. Typically, an f5 load balancer will check if a service is up and running by opening a connection to a port every second. If it can open a connection to the point, f5 considers the service to be operational.

From f5's point of view, opening a port but not making a request is the lowest-impact, safest way to test a service is in operation. With API Connect, nothing could be farther from the truth.

- From DataPower's point of view, opening a port and not making a request is an error. A dropped connection. Thus, it becomes an error log entry. Once every second. This amounts to 1MB of logs every minute. Logs rolling over every 5 minutes. Legitimate log errors become harder to detect because they get drowned out and rolled off the logs so quickly.
- Openning a connection only tests if the API Gateway port is open. It doesn't test that the gateway is actually delivering APIs.

Instead, at least one catalogue on a gateway service should have a public API that delivers a `GET /healthz` endpoint, and the load balancer should be configured to call that endpoint with each once-per-second health check. If the load balancer calls that endpoint and gets either an HTTP 200 or 204 back, then it can consider the gateway service to be healthy.

## Usable endpoint DNS names

This is particularly important for API Manager, the Developer Portal WWW endpoints, and the API Gateway's endpoint. These names are the names you will present to your users. Nobody will remember `portal.amr51f75kj.dev.nttntqr8kt.capnajax.com`. The `amr51f75kj` and `nttntqr8kt` might be meaningful to you, you have a very specific naming convention to help you manage thousands of servers, but they have no meaning to your users. Give them something meaningful. You can use your internal name for your actual machines, but give your users a `CNAME` to something more meaningful.

```bind9
$ORIGIN dev.capnajax.com
@       IN CNAME api-gw.gp8yfh0ivv.dev.hmat247lk0.capnajax.com.
portal  IN CNAME portal.amr51f75kj.dev.nttntqr8kt.capnajax.com.
apim    IN CNAME mgmt.gly6euo7bo.dev.nttntqr8kt.capnajax.com.
```

This is mostly a concern for development services as production services are normally behind load balancers.

## A runbook

What happens if there is a disaster? What happens if a backhoe breaks your internet connection? What happens if a transformer goes bang? A server lets its smoke out? A power outage? A disk fails?

What happens if you need to do scheduled maintenance? A fixpack install? 

Does your staff know what to do? Do they know how to move the servers to your backup data center? Do they know how to install a fixpack while minimizing downtime? Are they going to get everything done right when they are under pressure or might they miss a step?

Runbooks are like pilots' flight manuals. Your admins know what they have to do every day, but in emergencies, they resort to these runbooks to make sure they get every step right and they know whom to talk to if they need help with something outside their control. These runbooks reduce downtime and prevent data loss.

A runbook is only effective if it's tested. Your team should perform an annual disaster recovery drill, following the instructions in the runbook, to expose any issues with it. Remember, if there's a disaster affecting API Connect hosts in a data center, there's probably a disaster affecting all the hosts in the data center, so your team will be multitasking, distracted, and stressed as they try to bring your company's business back online.

## ISO Ignored mode

This is only applicable to OVA installations and is a new feature of API Connect 10.0.1.5-eus.

Many companies operate API Connect in clusters of VMWare hosts spread across multiple data centers and cannot guarantee the ISO will be available should the VM have to move to a different machine. In these environments, once virtual machines have been set up and booted, [set `iso-ignored` mode](https://www.ibm.com/docs/en/api-connect/10.0.1.x?topic=connect-appliance-boot-mode-configuration) to remove the need for the ISO needed at install time.

## Backups

IBM has one backup and restore strategy that is supported [[doc]](https://www.ibm.com/docs/en/api-connect/10.0.1.x?topic=mac-backing-up-restoring). Many companies use vMotion and they will usually have success with that, but IBM cannot provide support when things go wrong unless the supported backup mechanism is available. Note: when operating two data centers, the backups should reside in the backup datacenter, not the primary one, because in case the primary datacenter goes down, the backup files must be available to the backup datacenter.

Note that analytics backups require S3-compatible storage.

# Conclusion

Every installer, administrator, and developer of API Connect should strive to provide the most stable, most usable, and most professional-looking API Connect experience possible. The tips above are essential to providing just that.
