CA_ROOT=/etc/pki/myCA

# information of your Certificate Authority
COUNTRY=JP
STATE=Niigata
ORGANIZATION=My Great Company
CA_NAME=ca.example.com

# lifetime of certificates
EXPIRE_CERT=366
EXPIRE_CA=3660
EXPIRE_CRL=10

# Type of certificates
TYPE=ecdsa
SIZE=256

# default destination
MAILTO=root

# ------ end of configuration ----------------------------------------------

# distingish names
CA_CERT_DN=C=${COUNTRY}, ST=${STATE}, O=${ORGANIZATION}, CN=${CA_NAME}
CLIENT_CERT_DN=C=${COUNTRY}, ST=${STATE}, O=${ORGANIZATION}, CN=${USER}

# files and directories
CA_CERT_DIR=${CA_ROOT}/cacerts
CA_PUB=${CA_CERT_DIR}/root.cert.pem
CA_KEY=${CA_CERT_DIR}/root.key.pem
SERVER_CERT_DIR=${CA_ROOT}/servers
CLIENT_CERT_DIR=${CA_ROOT}/clients
CRL_DIR=${CA_ROOT}/crls
CRL=${CRL_DIR}/crl.pem
CA_DIST_DIR=${CA_ROOT}/dist

all: ${CA_PUB} ${CRL}

## issue a client certificate.
## Usage: make USER=name MAILTO=mail issue
##
CKEY=${CLIENT_CERT_DIR}/${USER}.key.pem
CPUB=${CLIENT_CERT_DIR}/${USER}.cert.pem
issue: ${CA_PUB} ${CRL}
	mkdir -p ${CLIENT_CERT_DIR}
	strongswan pki --gen --type ${TYPE} --size ${SIZE} --outform pem > ${CKEY}
	chmod 600 ${CKEY}
	strongswan pki --pub --in ${CKEY} --type ${TYPE} \
	| strongswan pki --issue --lifetime ${EXPIRE_CERT} \
	                 --cacert ${CA_PUB} --cakey ${CA_KEY} \
	                 --dn "C=${COUNTRY}, O=${ORGANIZATION}, CN=${USER}" \
	                 --flag clientAuth \
	                 --san ${USER} --outform pem \
	             > ${CPUB}
	openssl pkcs12 -export -legacy \
	               -inkey ${CKEY} -in ${CPUB} \
	               -name "${ORGANIZATION} client certificate" \
	               -out ${CLIENT_CERT_DIR}/${USER}.p12
	echo | mail -a ${CLIENT_CERT_DIR}/${USER}.p12 \
	            -s "Client Certificate for ${USER}" \
	            ${MAILTO}

## revoke a client certificate.
## Usage: make USER=name REASON=reason revoke
## REASON: {key-compromise|ca-compromise|affiliation-changed|superseded|cessation-of-operation|certificate-hold}
##
revoke: ${CA_PUB} ${CRL}
	strongswan pki --signcrl --lifetime=${EXPIRE_CRL} --basecrl=${CRL} \
	               --cacert ${CA_PUB} --cakey ${CA_KEY} \
	               --reason ${REASON} --cert ${CPUB} --outform pem \
	           > ${CRL}.new \
	&& mv -f ${CRL}.new ${CRL}

## update the CRL.
## Usage: make update
##
update: ${CA_PUB} ${CRL}
update: ${CA_PUB} ${CRL}
	strongswan pki --signcrl --lifetime=${EXPIRE_CRL} --basecrl=${CRL} \
	               --cacert ${CA_PUB} --cakey ${CA_KEY} --outform pem \
	           > ${CRL}.new \
	&& mv -f ${CRL}.new ${CRL}

## issue a server certificate.
## Usage: make SERVER=name server
##
SKEY=${SERVER_CERT_DIR}/${SERVER}.key.pem
SPUB=${SERVER_CERT_DIR}/${SERVER}.cert.pem
server: ${CA_PUB}
	mkdir -p ${SERVER_CERT_DIR}
	strongswan pki --gen --type ${TYPE} --size ${SIZE} --outform pem > ${SKEY}
	chmod 600 ${SKEY}
	strongswan pki --pub --in ${SKEY} --type ${TYPE} \
	| strongswan pki --issue --lifetime ${EXPIRE_CERT} \
	                 --cacert ${CA_PUB} --cakey ${CA_KEY} \
	                 --dn "C=${COUNTRY}, O=${ORGANIZATION}, CN=${SERVER}" \
	                 --san ${SERVER} --san *.${SERVER} \
	                 --flag serverAuth --flag ikeIntermediate --outform pem \
	             > ${SPUB}

# create an initial crl.
${CRL}: ${CA_PUB}
	mkdir -p ${CRL_DIR}
	strongswan pki --signcrl --cacert ${CA_PUB} --cakey ${CA_KEY} \
	               --lifetime=${EXPIRE_CRL} --outform pem \
	           > ${CRL}

## create a new CA.
## Usage: make
##
${CA_PUB}:
	mkdir -p ${CA_CERT_DIR}
	strongswan pki --gen --type ${TYPE} --size ${SIZE} --outform pem > ${CA_KEY}
	chmod 600 ${CA_KEY}
	strongswan pki --self --ca --lifetime ${EXPIRE_CA} \
	               --in ${CA_KEY} --type ${TYPE} \
	               --san "${CA_CERT_DN}" \
	               --dn "${CA_CERT_DN}" --outform pem \
	           > ${CA_PUB}
	openssl x509 -in ${CA_PUB} -outform DER -out ${CA_CERT_DIR}/root.cert.der
	echo | mail -a ${CA_CERT_DIR}/root.cert.der \
	            -s "${CA_NAME} Root Certificate" \
	            ${MAILTO}

## destroy the CA.
## Usage: make clean
##
clean:
	rm -rf ${CA_CERT_DIR} ${CLIENT_CERT_DIR} ${SERVER_CERT_DIR} ${CRL_DIR}

## display help
## Usage: make help
##
help:
	sed -n -e 's/^## \?//p' Makefile
