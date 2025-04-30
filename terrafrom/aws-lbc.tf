data "aws_iam_policy_document" "aws_lbc" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}


resource "aws_iam_role" "aws_lbc" {
  name               = "${aws_eks_cluster.eks.name}-aws-lbc"
  assume_role_policy = data.aws_iam_policy_document.aws_lbc.json
  depends_on = [ aws_eks_cluster.eks ]
}

resource "aws_iam_policy" "aws_lbc" {
  policy = file("lbControllerPolicy.json")
  name = "AWSLoadBalancerControllerIAMPolicy-${aws_eks_cluster.eks.name}"
}

resource "aws_iam_role_policy_attachment" "aws_lbc" {
  policy_arn = aws_iam_policy.aws_lbc.arn
  role       = aws_iam_role.aws_lbc.name
  
}

resource "aws_eks_pod_identity_association" "aws_lbc" {
  cluster_name = aws_eks_cluster.eks.name
  namespace    = "kube-system"
  service_account = "aws-load-balancer-controller"

  role_arn     = aws_iam_role.aws_lbc.arn
  depends_on   = [aws_iam_role_policy_attachment.aws_lbc]
}

provider "kubernetes" {
  host                   = aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks.name]
  }
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks.name]
    }
  }
}

resource "helm_release" "aws_lbc" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace = "kube-system"
  version    = "1.7.2"

  set {
    name  = "clusterName"
    value = aws_eks_cluster.eks.name
  }

  set {
    name  = "ClusterName"
    value = aws_eks_cluster.eks.name
  }

  set {
    name  = "ServiceAccount.name"
    value = "aws-load-balancer-controller"
  }

  #depends_on = [helm_release.cluster_autoscaler]
  
} 