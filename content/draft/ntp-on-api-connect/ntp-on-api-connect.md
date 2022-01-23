# NTP on API Connect

API Connect clusters can behave oddly if their clocks go out of sync and this can cause many unusual behaviors with the databases. This is particularly a problem with API Connect clusters deployed on VMWare in air-gapped environments. By default, the OVAs are configured to use NTP services at `ntp.ubuntu.com`, but these servers are not available if the API Connect cluster cannot reach the internet. Even if you can reach Ubuntu's NTP servers, it's best to use your local NTP servers.

This article will cover how to configure NTP services on API Connect Management, Analytics, and Portal.

## At install time

The best way to configure NTP services on API Connect is at install time using an extra values file. The IBM Documentation describes this process.

Configuring use of an external NTP server
* [API Connect 2018.4.1.9+](https://www.ibm.com/docs/en/api-connect/2018.x?topic=environment-configuring-use-external-ntp-server)
* [API Connect 10](https://www.ibm.com/docs/en/api-connect/10.0.1.x?topic=options-configuring-use-external-ntp-server)

## Post-install

Unfortunately, the extra values file only helps at install time. However, the `timesyncd` can be configured by hand at any time. It's a more tedious process, and it must be repeated on each machine.


### Review the current status of timesyncd (the local NTP service)

```sh
$> sudo systemctl status systemd-timesyncd.service
```

### Edit the NTP config file

```sh
$> sudo vi /etc/systemd/timesyncd.conf
```

Uncomment and change the line that starts with `#NTP=` to `NTP=ntp1.local ntp2.local ntp3.local` (of course, use your own servers) and separate them with spaces, not commas.

Example: 

```
[Time]
NTP=10.11.0.9 10.11.0.8
#FallbackNTP=ntp.ubuntu.com
#RootDistanceMaxSec=5
#PollIntervalMinSec=32
#PollIntervalMaxSec=2048
```

### Restart timesyncd

```sh
$> sudo systemctl restart systemd-timesyncd.service
```

### Review the status

```sh
$> sudo systemctl restart systemd-timesyncd.service
● systemd-timesyncd.service - Network Time Synchronization
     Loaded: loaded (/lib/systemd/system/systemd-timesyncd.service; enabled; vendor preset: enabled)
     Active: active (running) since Fri 2021-12-31 04:46:38 UTC; 13min ago
       Docs: man:systemd-timesyncd.service(8)
   Main PID: 2822182 (systemd-timesyn)
     Status: "Initial synchronization to time server 10.11.0.9:123 (10.11.0.9)."
      Tasks: 2 (limit: 38499)
     Memory: 1.6M
     CGroup: /system.slice/systemd-timesyncd.service
             └─2822182 /lib/systemd/systemd-timesyncd
```

You should see your new time servers in the Status: line. If the Status line says “Idle” or shows “`ntp.ubuntu.com`”, you probably mistyped the server hostnames in in the config file.

## Conclusion

We covered how to configure NTP services on API Connect Management, Analytics, and Portal subsystems. It is critical to ensure your clocks are in sync to keep your API Connect servers stable.
