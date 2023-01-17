#!/bin/bash

# Remove from local docker repo
docker image rm gcr.io/fitcentive-dev/flutter-web-app:1.0
docker image rm gcr.io/fitcentive-dev/flutter-web-app

# Remove existing gcr image
echo "y" | gcloud container images delete gcr.io/fitcentive-dev/flutter-web-app:1.0 --force-delete-tags

# Build and push new image
docker build ../. -t gcr.io/fitcentive-dev/flutter-web-app:1.0
docker push gcr.io/fitcentive-dev/flutter-web-app:1.0

kubectl apply -f deployment/gke-dev-env/