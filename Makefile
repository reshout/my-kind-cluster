install: create_cluster deploy_metrics_server deploy_ingress_nginx deploy_efk deploy_krakend

uninstall: delete_cluster

create_cluster:
	kind create cluster --name=kind --config=kind/config.yaml

delete_cluster:
	kind delete cluster --name=kind

deploy_metrics_server:
	kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
	kubectl patch -n kube-system deployment metrics-server --type=json -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

deploy_ingress_nginx:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s

deploy_efk:
	kubectl create namespace efk
	kubectl -n efk create -f elasticsearch
	kubectl -n efk create -f kibana

deploy_krakend:
	kubectl create namespace apigw
	kubectl -n apigw create configmap krakend --from-file=krakend/config/krakend.json
	kubectl -n apigw apply -f krakend/deployment

undeploy_krakend:
	kubectl -n apigw delete -f krakend/deployment
	kubectl -n apigw delete configmap krakend
	kubectl delete namespace apigw

reload_krakend: undeploy_krakend deploy_krakend
	kubectl -n apigw wait pod --selector=app=krakend --for=condition=ready --timeout=30s
	kubectl -n apigw logs -f --selector=app=krakend
