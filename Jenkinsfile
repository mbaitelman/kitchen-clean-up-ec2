pipeline {
    agent {
        docker {
            image 'hashicorp/terraform:0.12.20'
            args '--entrypoint=""'
        }
    }
    parameters {    
        choice choices: ['us-west-2', 'us-east-2'], description: '', name: 'region'
        choice choices: ['Plan', 'Apply', 'Destroy'], description: '', name: 'action'
        string defaultValue: '', description: '', name: 'target', trim: true    
    }

    triggers {
        pollSCM 'H/5 * * * *'
    }

    options {
      timeout(15)
      timestamps()
      ansiColor('xterm')
      disableConcurrentBuilds()
      lock('terraform-lock')
    }

    stages {
        stage('Init') {
            steps {
                script {
                    def changesExist = -1
                    def target = "${params.target}"                    
                    env.targetString = ""
                    if (target != '') {
                        target.split(",").each { moduleName ->
                            env.targetString += "-target ${moduleName} "
                        }
                    }                    
                }
                sh 'terraform version'
                withAWS(credentials: 'aws-credentials', region: 'us-west-2') {
                    sh 'terraform init'
                }
            }
        }
        stage('Validate') {
            steps {
                withAWS(region: 'us-west-2') {
                    sh 'terraform validate'
                }
            }
        }
        stage('Format') {
            steps {
                sh 'terraform fmt --recursive'
            }
        }        
        stage('Plan') {
            steps {
                withAWS(credentials: 'aws-credentials', region: 'us-west-2') {
                    script{
                        changesExist = sh label: 'terraform plan', returnStatus: true, script: "terraform plan ${env.targetString ?: ''} -detailed-exitcode" // 0 is no changes, 1 is error, 2 is changes to apply
                        if(changesExist == 1){
                            error('Error in terraform plan')
                        }
                    }
                }
            }
        }
        stage('Apply') {
            steps {
                withAWS(credentials: 'aws-credentials', region: 'us-west-2') {
                    script {
                        if(params.action == 'Destroy'){
                            sh "terraform destroy -input=false -auto-approve -force -parallelism 10 ${env.targetString ?: ''}"
                        } else {
                            sh "terraform apply -input=false -auto-approve -parallelism 10 ${env.targetString ?: ''}"
                        }
                    }
                }
            }
            when {
                allOf{
                    expression { env.BRANCH_NAME == "master"}
                    expression { return (changesExist == 2) }
                    expression { return (action == 'Apply') }
                }
            }
        }
    }
}
