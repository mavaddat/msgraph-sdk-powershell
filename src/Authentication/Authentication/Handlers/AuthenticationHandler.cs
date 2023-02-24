﻿// ------------------------------------------------------------------------------
//  Copyright (c) Microsoft Corporation.  All Rights Reserved.  Licensed under the MIT License.  See License in the project root for license information.
// ------------------------------------------------------------------------------


using Microsoft.Graph.Authentication;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;

namespace Microsoft.Graph.PowerShell.Authentication.Handlers
{
    internal class AuthenticationHandler : DelegatingHandler
    {
        private int MaxRetry { get; set; } = 1;

        public AzureIdentityAccessTokenProvider AuthenticationProvider { get; set; }

        public AuthenticationHandler(AzureIdentityAccessTokenProvider authenticationProvider)
        {
            AuthenticationProvider = authenticationProvider;
        }

        public AuthenticationHandler(AzureIdentityAccessTokenProvider authenticationProvider, HttpMessageHandler innerHandler)
            : this(authenticationProvider)
        {
            InnerHandler = innerHandler;
        }

        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage httpRequestMessage, CancellationToken cancellationToken)
        {
            // Authenticate request using AuthenticationProvider
            if (AuthenticationProvider != null)
            {
                // Fails to compile because AuthenticateRequestAsync accepts does not accept a HttpRequestMessage. It onlly accepts RequestInformation.
                // We should consider:
                // - Updating the AuthenticationProvider interface to accept a HttpRequestMessage via an overload.
                // - Providing conversion between HttpRequestMessage and RequestInformation.
                var accessToken = await AuthenticationProvider.GetAuthorizationTokenAsync(httpRequestMessage.RequestUri, cancellationToken: cancellationToken).ConfigureAwait(false);
                if (!string.IsNullOrEmpty(accessToken))
                    httpRequestMessage.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", accessToken);

                // TODO: Handle claims.

                HttpResponseMessage response = await base.SendAsync(httpRequestMessage, cancellationToken).ConfigureAwait(false);

                return response;
            }
            else
            {
                return await base.SendAsync(httpRequestMessage, cancellationToken).ConfigureAwait(false);
            }
        }
    }
}