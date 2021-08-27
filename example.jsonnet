local t = import 'kube-thanos/thanos.libsonnet';

// For an example with every option and component, please check all.jsonnet

local commonConfig = {
  config+:: {
    local cfg = self,
    namespace: 'thanos',
    version: 'v0.22.0',
    image: 'quay.io/thanos/thanos:' + cfg.version,
    objectStorageConfig: {
      name: 'thanos-objectstorage',
      key: 'thanos.yaml',
    },
    volumeClaimTemplate: {
      spec: {
        accessModes: ['ReadWriteOnce'],
        resources: {
          requests: {
            storage: '10Gi',
          },
        },
      },
    },
  },
};

local s = t.store(commonConfig.config {
  replicas: 1,
  serviceMonitor: true,
});

local q = t.query(commonConfig.config {
  replicas: 1,
  replicaLabels: ['prometheus_replica', 'rule_replica'],
  serviceMonitor: true,
});

local split = t.receiveSplit(commonConfig.config {
  replicas: 1,
  replicaLabels: ['receive_replica'],
  replicationFactor: 1,
});

{ ['thanos-store-' + name]: s[name] for name in std.objectFields(s) } +
{ ['thanos-query-' + name]: q[name] for name in std.objectFields(q) } +
{ ['thanos-receive-ingestor-' + name]: split.ingestor[name] for name in std.objectFields(split.ingestor) } +
{ ['thanos-receive-router-' + name]: split.router[name] for name in std.objectFields(split.router) }
