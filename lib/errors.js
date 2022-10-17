/**
 * Represents error, sent by Barion API.
 * @param {String} message - Error message.
 * @param {Array} errors - Barion's "Errors" array.
 */
class BarionError extends Error {
    constructor (message, errors) {
        super(message);
        this.name = this.constructor.name;
        this.errors = Array.isArray(errors) ? errors : [];
    }
}

/**
 * Represents structural error in the passed object.
 * This error is thrown before even the request is sent to the Barion API.
 * @param {String} message - Error message.
 * @param {Array} errors - Error messages of validation process.
 */
class BarionModelError extends Error {
    constructor (message, errors) {
        super(message);
        this.name = this.constructor.name;
        this.errors = Array.isArray(errors) ? errors : [];
    }
}

module.exports = {
    BarionError,
    BarionModelError
};
