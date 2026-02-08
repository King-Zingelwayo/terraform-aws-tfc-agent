import json
import os
import boto3
import logging
from typing import Dict, List

logger = logging.getLogger()
logger.setLevel(logging.INFO)

codebuild = boto3.client('codebuild')

def handler(event, context):
    """
    Trigger CodeBuild projects to run TFC agents.
    
    Can be triggered by:
    1. EventBridge (scheduled)
    2. API Gateway (webhook from TFC)
    3. Manual invocation
    """
    
    logger.info(f"Event: {json.dumps(event)}")
    
    # Get CodeBuild project names from environment
    projects = json.loads(os.environ['CODEBUILD_PROJECTS'])
    environment = os.environ['ENVIRONMENT']
    
    logger.info(f"Found {len(projects)} CodeBuild projects for environment: {environment}")
    
    results = []
    
    for project in projects:
        try:
            # Check if project is already running
            running_builds = codebuild.list_builds_for_project(
                projectName=project,
                sortOrder='DESCENDING'
            )
            
            # Get build details
            if running_builds['ids']:
                builds = codebuild.batch_get_builds(ids=running_builds['ids'][:5])
                
                # Check if any build is currently running
                active_build = any(
                    b['buildStatus'] == 'IN_PROGRESS' 
                    for b in builds['builds']
                )
                
                if active_build:
                    logger.info(f"Project {project} already has an active build, skipping")
                    results.append({
                        'project': project,
                        'status': 'SKIPPED',
                        'reason': 'Already running'
                    })
                    continue
            
            # Start new build
            response = codebuild.start_build(
                projectName=project
            )
            
            build_id = response['build']['id']
            logger.info(f"Started build {build_id} for project {project}")
            
            results.append({
                'project': project,
                'status': 'STARTED',
                'buildId': build_id
            })
            
        except Exception as e:
            logger.error(f"Error starting build for {project}: {str(e)}")
            results.append({
                'project': project,
                'status': 'ERROR',
                'error': str(e)
            })
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': f'Processed {len(projects)} projects',
            'results': results
        })
    }