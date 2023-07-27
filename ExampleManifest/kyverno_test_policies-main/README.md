# Kyverno_test_policies

This pattern guide you through the steps required to enforce a set of policies aimed to protect API services deployed on EKS clusters. Customers using the AWS EKS service can publish their APIs using the AWS Load Balancer Controller, which acts on their behalf and provisions ALBs or NLBs in order to balance incoming traffic to the cluster. 

Since these APIs can be publicly exposed, it is needed to apply a set of policies that guarantee that all the resources provisioned by the AWS Load Balancer Controller comply with common security best practices such as SSL Certificates, WAF Integration, Shield Advanced, SSL Security Policy, etc. In order to enforce these set of policies we will use Kyverno, an open-source project that can validate, mutate, and generate configurations through admission controls and background scans. Kyverno is a policy engine designed for Kubernetes and is a Cloud Native (CNCF) incubation project.

As part of this pattern, multiple policies will be delivered and explained to readers.
