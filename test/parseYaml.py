import yaml, pprint

yamlFile = open( 'init/init.yaml' )
dict = yaml.load( yamlFile )
yamlFile.close()

pprint.pprint( dict )
