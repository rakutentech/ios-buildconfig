def call() {
  slackSend channel: '#sdk-dev-ci',
        color: 'danger',
        message: "${currentBuild.fullDisplayName} failed! (<${env.BUILD_URL}|Open>)"
}