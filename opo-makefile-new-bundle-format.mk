
.PHONY: opo-build-clean
opo-build-clean:
	rm -rf build/_output

.PHONY: opo-ctrl-image
opo-ctrl-image: opo-build-clean
ifndef VERSION
	@echo VERSION not set
	@exit 1
endif
ifndef QUAY_NAMESPACE
	@echo QUAY_NAMESPACE not set
	@exit 1
endif
ifeq ($(uname -m),x86_64)
	ARCH=amd64
else ifeq ($(uname -m),ppc64le)
	ARCH=ppc64le
endif
	GOARCH=${ARCH} operator-sdk build quay.io/${QUAY_NAMESPACE}/openshift-pipelines-operator-controller:v${VERSION} --go-build-args "-o build/_output/bin/openshift-pipelines-operator"
	docker push quay.io/${QUAY_NAMESPACE}/openshift-pipelines-operator-controller:v${VERSION}
	sed -i 's/image:.*/image: quay.io\/'${QUAY_NAMESPACE}'\/openshift-pipelines-operator-controller:v'${VERSION}'/' deploy/operator.yaml

.PHONY: opo-bundle-image
opo-bundle-image:
ifndef VERSION
	@echo VERSION not set
	@exit 1
endif
ifndef REGISTRY_PATH
	@echo REGISTRY_PATH not set
	@exit 1
endif
	docker build -f bundle.Dockerfile -t ${REGISTRY_PATH}/openshift-jaeger-operator-midstr-bundle:v${VERSION} .
	docker push ${REGISTRY_PATH}/openshift-jaeger-operator-midstr-bundle:v${VERSION}

.PHONY: opo-update-index-image
opo-index-image:
ifndef VERSION
	@echo VERSION not set
	@exit 1
endif
ifndef REGISTRY_PATH
	@echo REGISTRY_PATH not set
	@exit 1
endif
	# NOTE: tag index image as latest as CatalogSource Resources on clusters will always get the latest updates
	# if we tag the index image with a version, we will have to update the index image reference in CatalogSources on
	# on all cluster using this operator
	opm index add --bundles ${REGISTRY_PATH}/openshift-jaeger-operator-midstr-bundle:v${VERSION} \
 		--tag ${REGISTRY_PATH}/openshift-jaeger-operator-midstr-index:latest --container-tool docker
	docker push ${REGISTRY_PATH}/openshift-jaeger-operator-midstr-index:latest

        # Necessary because OLM catalog pods have imagePullPolicy: ifnotpresent !!!
	docker tag  ${REGISTRY_PATH}/openshift-jaeger-operator-midstr-index:latest ${REGISTRY_PATH}/openshift-jaeger-operator-midstr-index:${VERSION}
	docker push ${REGISTRY_PATH}/openshift-jaeger-operator-midstr-index:${VERSION}
