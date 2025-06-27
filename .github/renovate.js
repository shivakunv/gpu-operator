module.exports = {
  platform: "github",
  autodiscover: true, // will work for current repo updates
  allowedRepos: ["shivakunv/gpu-operator"],
  repository: "https://github.com/shivakunv/gpu-operator.git",
  forkProcessing: "enabled",
  onboarding: false,
  enabled: true,
  hostRules: [
    {
      hostType: "docker",
      matchHost: "nvcr.io",
      username: "$oauthtoken",
      password: process.env.RENOVATE_TOKEN
    }
  ],
  customManagers: [
    {
      customType: "regex",
      managerFilePatterns: ["^deployments/gpu-operator/.*\\.ya?ml$"],
      matchStrings: [
        "image:\\s*\"?(?<depName>[^:@\"]+)(?::(?<currentValue>[\\w.\\-]+))?\"?"
      ],
      datasourceTemplate: "docker"
    }
  ]
};