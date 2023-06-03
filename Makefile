.PHONY: install uninstall create_cluster deploy_metrics_server deploy_ingress_nginx deploy_logging deploy_krakend delete_cluster

install: create_cluster deploy_metrics_server deploy_ingress_nginx deploy_logging deploy_krakend

uninstall: delete_cluster

create_cluster:
	kind create cluster --name=kind --config=kind/config.yaml

deploy_metrics_server:
	kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
	kubectl patch -n kube-system deployment metrics-server --type=json -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

deploy_ingress_nginx:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s

deploy_logging:
	kubectl create namespace kube-logging
	kubectl create secret generic elasticsearch-pw-elastic --from-literal password=123456 -n kube-logging
	kubectl apply -f elasticsearch/master
	kubectl apply -f elasticsearch/data
	kubectl apply -f elasticsearch/client

deploy_krakend:
	kubectl create namespace krakend
	kubectl apply -f krakend/deployment

delete_cluster:
	kind delete cluster --name=kind
