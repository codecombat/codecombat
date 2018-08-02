var dexecure = {
	"server": {
		"codecombat.com": "codecombat.dexecure.net",
		"www.codecombat.com": "codecombat.dexecure.net",
		"staging.codecombat.com": "codecombat-staging.dexecure.net"
	},
	"firstPartyDomain": [
		"codecombat.com",
		"www.codecombat.com",
		"staging.codecombat.com"
	],
	"optimisationsEnabled": true,
	"debugMode": false,
	"imageMatchRegex": "\\.jpe?g|\\.png",
	"pagesEnabled": [
		""
	]
};"use strict";function isFirstPartyDomain(e){for(var r=new URL(e),o=dexecure.firstPartyDomain,t=o.length-1;t>=0;t--)if(o[t].toLowerCase()==r.host.toLowerCase())return!0;return!1}function changeToDexecureURL(e){var r=new URL(e);return dexecure.debugMode&&console.log("inputURL is ",e),dexecure.debugMode&&console.log("inputURL.hostname is ",e.hostname),r.hostname=dexecure.server[r.hostname],dexecure.debugMode&&console.log("changedURL.hostname is ",r.hostname),r.pathname.startsWith("/file") ? r.searchParams.set("resize", "none") : null,dexecure.debugMode&&console.log("changedURL is ",r.href),r.href}function isPageEnabled(e){return!0}dexecure.optimisationsEnabled&&(self.addEventListener("install",function(e){dexecure.debugMode&&console.log("install triggered"),e.waitUntil(self.skipWaiting())}),self.addEventListener("activate",function(e){e.waitUntil(self.clients.claim())}),self.addEventListener("fetch",function(e){dexecure.debugMode&&console.log("fetch triggered");var r={};e.request.headers.has("Accept")&&(r.Accept=e.request.headers.get("Accept"));var o=new Headers(r),t=new RegExp(dexecure.imageMatchRegex,"i");if(dexecure.debugMode&&console.log("input url is ",e.request.url),isPageEnabled(e.request.referrer)&&t.test(e.request.url.toLowerCase())&&isFirstPartyDomain(e.request.url)){var n=changeToDexecureURL(e.request.url);n=decodeURIComponent(n),dexecure.debugMode&&console.log("output url is ",n),e.respondWith(fetch(n,{mode:"cors",headers:o}).then(function(r){if(r.ok)return r;throw dexecure.debugMode&&console.log("Responding with original image as optimiser was not reachable ",e.request.url),new Error("Unable to fetch optimised image")}).catch(function(r){return dexecure.debugMode&&(console.log("Sending original image as an error occured when trying to optimise ",e.request.url),console.log("The error was ",r)),fetch(e.request)}))}}));
