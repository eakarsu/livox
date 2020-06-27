var exec = require('cordova/exec');

/**
 * Create the AEON context objects if required.
 */
if (AEON == null)
    AEON = {}
if (AEON.Authentication == null)
    AEON.Authentication = {}

/**
 * Empty callback object for successful authentication attempts.
 */
AEON.Authentication.onAuthenticationSuccess = function() {}

/**
 * Empty callback object for authentication errors.
 */
AEON.Authentication.onAuthenticationError = function() {}

/**
 * Attempts to authenticate the client with the "companyId" and the "companySecret"
 * provided by the user.

 * @param {Object} companyId
 * @param {Object} companySecret
 */
AEON.Authentication.authenticateCompany = function(companyId, companySecret) {

    exec(AEON.Authentication.onAuthenticationSuccess, AEON.Authentication.onAuthenticationError, "AEON.Authentication", "authenticateCompany", [companyId, companySecret]);
};

module.exports = AEON.Authentication;
