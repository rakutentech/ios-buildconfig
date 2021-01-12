def call() {
  	slackSend channel: "${env.SLACK_CHANNEL_SDK}",
        color: 'danger',
        message: "${currentBuild.fullDisplayName} failed! (<${env.BUILD_URL}|Open>)"
}