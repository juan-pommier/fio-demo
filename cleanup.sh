kubectl delete -f clone/nginx-service-clone.yaml
kubectl delete -f deployment/nginx-service.yaml
kubectl delete -f clone/nginx-deployment-clone.yaml
kubectl delete -f deployment/nginx-deployment.yaml
kubectl delete pvc nginx-clone-pvc
kubectl delete volumesnapshot snapshot-nginx-demo-pvc
kubectl delete -f deployment/nginx-pvc.yaml
