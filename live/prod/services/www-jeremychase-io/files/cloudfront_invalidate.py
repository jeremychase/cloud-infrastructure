import logging
import boto3

cloudfront = boto3.client('cloudfront')
codepipeline = boto3.client('codepipeline')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

#
# Inspired by:
#   https://docs.aws.amazon.com/code-samples/latest/catalog/lambda_functions-codepipeline-MyCodePipelineFunction.py.html
#   https://kupczynski.info/2019/01/09/invalidate-cloudfront-with-lambda-s3.html
#


def lambda_handler(event, context):
    # BUG(medium) Document
    # BUG(low) Allow execution from triggers other than CodePipeline
    logger.info('Starting CloudFront invalidation Lambda handler')
    ret = 'Failure'

    try:
        # Extract the Job ID
        job_id = event['CodePipeline.job']['id']

        # Extract the Job Data
        job_data = event['CodePipeline.job']['data']

        # Invalidate the entire distribution
        batch = {
            'Paths': {
                'Quantity': 1,
                'Items': ['/*']  # Wildcard must start with slash to work
            },
            'CallerReference': job_id
        }

        # Pull distID out of UserParameters
        distID = job_data['actionConfiguration']['configuration']['UserParameters']

        # Perform invalidation
        cloudfront.create_invalidation(
            DistributionId=distID,
            InvalidationBatch=batch,
        )

        # Notify codepipeline of success
        codepipeline.put_job_success_result(jobId=job_id)

        # Set return value
        ret = 'Success'

    except Exception as ex:
        # Get some sense of what the error was
        message = type(ex).__name__
        logger.error(f'Putting job failure: {message}')

        # Attempt to notify CodePipeline of failure
        codepipeline.put_job_failure_result(jobId=job_id, failureDetails={
            'message': message, 'type': 'JobFailed'})

    # Log and return
    logger.info(f'{ret}')
    return ret
