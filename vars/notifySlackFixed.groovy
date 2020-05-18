def call() {
  slackSend channel: '#sdk-dev-ci',
      color: 'good',
      message: "${currentBuild.fullDisplayName} is back to normal (<${env.BUILD_URL}|Open>)"
}