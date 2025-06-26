module.exports = {
  platform: "github",
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