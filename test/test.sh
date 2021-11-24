#!/bin/bash

# variables
manifest="test.yml"
name="nat-gateway"
namespace="nat-gateway"
seconds=10

# Check if the namespace exists in the cluster
result=$(kubectl get namespace \
    --output 'jsonpath={.items[?(@.metadata.name=="'$namespace'")].metadata.name'})

if [[ -n $result ]]; then
    echo "[$namespace] namespace already exists in the cluster"
else
    echo "[$namespace] namespace does not exist in the cluster"
    echo "Creating [$namespace] namespace in the cluster..."
    kubectl create namespace $namespace
fi

# Check if demo pod exists in the namespace
result=$(kubectl get deployment \
    --namespace $namespace \
    --output 'jsonpath={.items[?(@.metadata.name=="'$name'")].metadata.name'})

if [[ -n $result ]]; then
    echo "[$name] deployment already exists in the [$namespace] namespace"
else
    echo "Creating [$name] deployment in the [$namespace] namespace..."
    kubectl apply -f $manifest --namespace $namespace
fi

# Get pod name
pod=$(kubectl get pod \
    --namespace $namespace \
    --output 'jsonpath={.items[].metadata.name}')

if [[ -z $pod ]]; then
    echo 'no pod found, please check the name of the deployment and namespace'
    exit
fi

# Wait for the pod to be up and running
kubectl wait pod --namespace $namespace --for=condition=ready -l app=nat-gateway 

# Sleep 10 seconds to let the pod invoke an external service to collect its public IP address
echo "Sleeping for $seconds seconds..."
for ((i=0;i<$seconds;i++))
do
    echo -n "."
    sleep 1
done
echo ""

# Print the pod log
kubectl logs $pod --namespace $namespace