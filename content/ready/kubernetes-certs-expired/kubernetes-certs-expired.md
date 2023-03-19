# Renewing Kubernetes certificates after they have expired

Renewing Kubernetes certificates before they expire is easy. In fact, newer versions renew them automatically by default. However, versions of Kubernetes older than 1.17 will have automatic renewal disabled by default.

* [Checking the certificates' expiration date](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/#check-certificate-expiration)
* [Automatic certificate renewal](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/#automatic-certificate-renewal)
* [Renewing certificates manually](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/#manual-certificate-renewal)

## After they expire

If you're reading this, it's probably too late to renew the certificates the easy way because the certificates have already expired. You opened your terminal one day, tried to check your pod status like you do every other day, and suddenly you can't.

### What the error looks like

```sh
> kubectl get pods
Unable to connect to the server: x509: certificate has expired or is not yet valid: current time [date] is after [expiration_date]
```

If you try to reboot your server, it gets even worse. The API server can't even start up and `kubelet` can't even connect the master node.

```sh
> systemctl restart kubelet
> journalctl -xe -u kubelet
Sep 12 09:57:34 athabasca kubelet[3902708]: E0912 09:57:34.769056 3902708 kubelet.go:2407] "Error getting node" err="node \"athabasca\" not found"
Sep 12 09:57:34 athabasca kubelet[3902708]: E0912 09:57:34.869738 3902708 kubelet.go:2407] "Error getting node" err="node \"athabasca\" not found"
Sep 12 09:57:34 athabasca kubelet[3902708]: E0912 09:57:34.970179 3902708 kubelet.go:2407] "Error getting node" err="node \"athabasca\" not found"
Sep 12 09:57:35 athabasca kubelet[3902708]: E0912 09:57:35.070676 3902708 kubelet.go:2407] "Error getting node" err="node \"athabasca\" not found"
Sep 12 09:57:35 athabasca kubelet[3902708]: E0912 09:57:35.171646 3902708 kubelet.go:2407] "Error getting node" err="node \"athabasca\" not found"
Sep 12 09:57:35 athabasca kubelet[3902708]: E0912 09:57:35.272343 3902708 kubelet.go:2407] "Error getting node" err="node \"athabasca\" not found"
Sep 12 09:57:35 athabasca kubelet[3902708]: E0912 09:57:35.372908 3902708 kubelet.go:2407] "Error getting node" err="node \"athabasca\" not found"
Sep 12 09:57:35 athabasca kubelet[3902708]: E0912 09:57:35.473354 3902708 kubelet.go:2407] "Error getting node" err="node \"athabasca\" not found"
```

This shows the most critical error, the API server. You may have generated other `kubectl` contexts with their own keys, but they won't be much use of the API server is out of service.

### Renewing the certificates

Because the certificate has already expired, a little surgery is required. Back up your server first, and once that's complete, we'll generate new certificates

First we'll regenerate the API server certificates:

```sh
> cd /etc/kubernetes

# just a temp backup folder
> mkdir -p ~/kubernetes-backup-keys

# copies the whole directory tree with permissions intact
> tar cf - * | (cd ~/kubernetes-backup-keys ; tar xvf -) 

> cd /etc/kubernetes/pki

# remove the old certificates because they will interfere with the process
> rm {apiserver.crt,apiserver-etcd-client.key,apiserver-kubelet-client.crt,front-proxy-ca.crt,front-proxy-client.crt,front-proxy-client.key,front-proxy-ca.key,apiserver-kubelet-client.key,apiserver.key,apiserver-etcd-client.crt}
> rm etcd/{peer*,server*,healthcheck-client.*}

# regenerate the keys
> kubeadm init phase certs all --apiserver-advertise-address 192.168.1.200
```

Ensure that the `kubeadm` command completed without errors. If there are errors, it's likely due to a file being in place that the `kubeadm` command refuses to overwrite. Clear out all the new cert and key files, plus the one it's complaining about, and try again until the command completes without errors.

The process for regenerating the `kubectl` conf files is similar

```sh
> cd /etc/kubernetes

> rm admin.conf controller-manager.conf kubelet.conf scheduler.conf

> kubeadm init phase kubeconfig all
```

Again, ensure the command finished without error. Once this is complete, you may use the new `kubectl` conf files in `/etc/kubernetes` to administer your cluster.

## Conclusion

Obviously, if you're reading this article, you screwed up and you don't want to be back here a year from now. Check your cert expiration dates and set a reminder to renew the certs a week or two before they expire again, or even better, set up an automatic renewal.
