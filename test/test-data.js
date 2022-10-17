/**
 * These objects are used in tests.
 */
module.exports = {
    fetchTest: {
        successResponse: {
            Errors: [],
            success: true,
            stringVal: 'ok'
        },
        binarySuccessResponse: {
            // top secret url, do not share with the public
            body: Buffer.from('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
            headers: {
                'Content-Type': 'application/pdf'
            }
        },
        errorResponse: {
            body: {
                Errors: [
                    { Title: 'Authentication failed.', HappenedAt: '2019-01-19T18:46:51.0808761Z' }
                ]
            },
            status: 400
        },
        internalErrorResponse: {
            body: { Message: 'An error has occurred.' },
            status: 500
        },
        notJsonResponse: '<html></html>',
        networkErrorResponse: {
            throws: 'Failed to fetch data'
        }
    }
};
