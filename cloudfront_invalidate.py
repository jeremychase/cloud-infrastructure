import logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# BUG(high) implement


def lambda_handler(event, context):
    logger.debug('debug')
    logger.info('info')
    logger.warning('warning')
    logger.error('error')
    logger.critical('critical')

    return "hello"
