module.exports = {
  platform: "github",
  autodiscover: true, // will work for current repo updates
  repositories: ["https://github.com/shivakunv/gpu-operator.git"], // should be commented out as it is not needed in case of non forked repos
  hostRules: [
    {
      hostType: "docker",
      matchHost: "nvcr.io",
      username: "$oauthtoken",
      password: "***********"
    }
  ],
  customManagers: [
    {
      customType: "regex",
      managerFilePatterns: ["/^deployments/gpu-operator/.*\\.ya?ml$/"],
      matchStrings: [
        "image:\\s*\"?(?<depName>[^:@\"]+)(?::(?<currentValue>[\\w.\\-]+))?\"?"
      ],
      datasourceTemplate: "docker"
    }
  ]
};