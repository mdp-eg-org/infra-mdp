help:		## Show this help.
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'


uninstall-argocd:	## uninstall Argocd cluster wide 
	kustomize build --enable-alpha-plugins  argocd  | kubectl delete -f -

install-argocd:	## install Argocd cluster wide 
	kubectl create ns argocd || true
	kustomize build --enable-alpha-plugins  argocd | kubectl apply -f -

get-argocd-password: ## get the name pod name of argocd-server deployment
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d ;echo

install-base-app-bootstrap: ## install Argocd base-apps bootstrap application
	kubectl apply -f argocd/base-apps-bootstrap.yaml -n argocd

install-centralized-app-bootstrap: ## install Argocd centralized-apps bootstrap application
	kubectl apply -f argocd/centralized-apps-bootstrap.yaml -n argocd

get-harbor-password: 
	kubectl -n harbor get secret harbor-core -o jsonpath="{.data.HARBOR_ADMIN_PASSWORD}" | base64 -d ;echo