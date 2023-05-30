# Simple CA with strongswan

This Makefile makes easier to administrate your own Certificate Authority (CA).

This CA is mainly useful to issue and/or revoke client certificates. 

## Requirements

* strongswan
* mailx

## Preparation

Download this Makefile to your host.

```
# mkdir -p "/etc/pki/myCA"
# curl -sSL "https://raw.githubusercontent.com/seinolab/simple-ca-with-strongswan/main/Makefile" -o "/etc/pki/myCA/Makefile"
```

Setup followings:

```
CA_ROOT=/etc/pki/myCA

# information of your Certificate Authority
COUNTRY=JP
STATE=Niigata
ORGANIZATION=My Great Company
CA_NAME=ca.example.com

# lifetime of certificates
EXPIRE_CERT=366
EXPIRE_CA=3660
EXPIRE_CRL=7

# Type of certificates
TYPE=ecdsa
SIZE=256

# default destination
MAILTO=root
```

## Usage

To create new CA, run this Makefile.

```
# make
```

To destroy your CA, run the target clean.

```
# make clean
```

To issue a new client certificate, run the target issue. This example shows to issue a new client certificate for user `alice` and send it to `alice@example.com` in .p12 format.

```
# make USER=alice@example.com MAILTO=alice@example.com issue
```

To revoke a client certificate, run the target revoke.  This example shows to revoke the cerificate for user `bob` with a reason `key-compromise`.

```
# make USER=bob@example.com REASON=key-compromise revoke
```

To update your certification revocation list (CRL), run the target update.  Note that CRL is required to update periodically, even if you didn't revoke any user.

```
# make update
```

