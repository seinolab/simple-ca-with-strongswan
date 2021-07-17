= Simple CA with strongswan =

This Makefile makes easier to administrate your own ceritificate authority (CA).

This CA is mainly useful to issue/revoke client certificates. 

== Requirements

* strongswan
* mailx

== Preparation

Download this Makefile to your host.

```
# mkdir -p "/etc/pki/${HOSTNAME}"
# curl "https://github/..." -o "/etc/pki/${HOSTNAME}"
```

Setup followings:

```
CA_ROOT=/etc/pki/${HOSTNAME}

# information of your certificate authority
COUNTRY=
STATE=
ORGANIZATION=
CA_NAME=

# lifetime of certificates
EXPIRE_CERT=366
EXPIRE_CA=3660
EXPIRE_CRL=7
```

== Usage

To create new CA, run this Makefile.

```
# make
```

To destroy your CA, run the target clean.

```
# make clean
```

To issue new client certificate, run the target issue.

```
# make USER=alice MAILTO=alice@example.com issue
```

To revoke a client certificate, run the target revoke.

```
# make USER=bob REASON=key-compromise revoke
```

To update your certification revocation list (CRL), run the target update.

```
# make update
```

