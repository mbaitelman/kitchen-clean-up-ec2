import json
import boto3

def lambda_handler(event, context):
    # TODO implement
    client = boto3.client('ec2')
    
    kitchen_security_groups = []
    kitchen_key_pairs = []
    kitchen_instances = []
    
    security_groups_dict = client.describe_security_groups(Filters=[
        {
            'Name': 'description',
            'Values': [
                'Test Kitchen for *',
            ]
        },
    ])
    security_groups = security_groups_dict['SecurityGroups']
    
    for groupobj in security_groups: 
        if 'Tags' in groupobj.keys():
            print(groupobj['Tags'])
#            tagsObj = groupobj['Tags']
#            if tagsObj['Key'] == 'OtherKey':
 #               print('HasKey')
        kitchen_security_groups.append(groupobj['GroupId'])
    
     
    key_pairs_dict = client.describe_key_pairs(
        Filters=[
        {
            'Name': 'key-name',
            'Values': [
                'kitchen-*',
            ]
        },
    ]
    )
    key_pairs = key_pairs_dict['KeyPairs']
    for key_pairs_obj in key_pairs:
        kitchen_key_pairs.append(key_pairs_obj['KeyName'])
        
    instances_dict = client.describe_instances(
        Filters=[
        {
            'Name': 'tag:Name',
            'Values': [
                'test-kitchen',
            ]
        },
    ]
    )    
    reservations = instances_dict['Reservations']
    for i in reservations:
        for i_obj in i['Instances']:
            kitchen_instances.append(i_obj['InstanceId'])
        

    print("Going to delete keys: " + str(kitchen_key_pairs))
    for kp in kitchen_key_pairs:
        print('deleting key: ' + kp)
        response = client.delete_key_pair(
            KeyName=kp
        )
        print (response)


    print('Going to delete instances: ' + str(kitchen_instances))   
    for inst in kitchen_instances:
        print('deleting instance: ' + inst)
        response = client.terminate_instances(
            InstanceIds=[inst]
            #,
            #Force=True|False
        )
        print(response)

    print("Going to delete SG's:" + str(kitchen_security_groups))
    for sg in kitchen_security_groups:
        print('deleting SG:' + sg)
        response = client.delete_security_group(
            GroupId=sg,
        )        
        print(response)

    return {
        'statusCode': 200,
        'body': 'All good'
    }
