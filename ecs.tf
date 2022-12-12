resource "aws_ecs_cluster" "web-cluster" {
  name               = var.cluster_name
  tags = {
    "env"       = "dev"
    "createdBy" = "binpipe"
  }
}

resource "aws_ecs_cluster_capacity_providers" "web-cluster" {
  cluster_name = aws_ecs_cluster.web-cluster.name

  capacity_providers = [aws_ecs_capacity_provider.test.name]

}

resource "aws_iam_service_linked_role" "ecs" {
  aws_service_name = "ecs.amazonaws.com"
}

resource "aws_ecs_capacity_provider" "test" {
  name = "capacity-provider-test"
  
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.asg.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 85
    }
  }
}

# update file container-def, so it's pulling image from ecr
resource "aws_ecs_task_definition" "task-definition-frontend" {
  family                = "frontend"
  container_definitions = file("container-definitions/container-def.json")
  network_mode          = "bridge"
  tags = {
    "env"       = "dev"
    "createdBy" = "binpipe"
    "createdBy1" = "binpipe1"
    "createdBy2" = "binpipe2"
  }
}

resource "aws_ecs_service" "frontend" {
  name            = "frontend-service"
  cluster         = aws_ecs_cluster.web-cluster.id
  task_definition = aws_ecs_task_definition.task-definition-frontend.arn
  desired_count   = 2
  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.lb_target_group_frontend.arn
    container_name   = "frontend"
    container_port   = 3000
  }
  # Optional: Allow external changes without Terraform plan difference(for example ASG)
  lifecycle {
    ignore_changes = [desired_count]
  }
  launch_type = "EC2"
  depends_on  = [aws_lb_listener.web-listener-frontend]
}


resource "aws_ecs_task_definition" "task-definition-backend" {
  family                = "backend"
  container_definitions = file("container-definitions/container-def-backend.json")
  network_mode          = "bridge"
  tags = {
    "env"       = "dev"
    "createdBy" = "binpipe"
  }
}

resource "aws_ecs_service" "backend" {
  name            = "backend-service"
  cluster         = aws_ecs_cluster.web-cluster.id
  task_definition = aws_ecs_task_definition.task-definition-backend.arn
  desired_count   = 2
  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.lb_target_group_backend.arn
    container_name   = "backend"
    container_port   = 3001
  }
  # Optional: Allow external changes without Terraform plan difference(for example ASG)
  lifecycle {
    ignore_changes = [desired_count]
  }
  launch_type = "EC2"
  depends_on  = [aws_lb_listener.web-listener-backend]
}




resource "aws_cloudwatch_log_group" "log_group" {
  name = "/ecs/frontend-container"
  tags = {
    "env"       = "dev"
    "createdBy" = "binpipe"
  }
}
