div.fancy-select {
	position: relative;
	font-weight: bold;
	text-transform: uppercase;
	font-size: 13px;
	color: #46565D;
}

div.fancy-select.disabled {
	opacity: 0.5;
}

div.fancy-select select:focus + div.trigger {
	box-shadow: 0 0 0 2px #4B5468;
}

div.fancy-select select:focus + div.trigger.open {
	box-shadow: none;
}

div.fancy-select div.trigger {
	border-radius: 4px;
	cursor: pointer;
	padding: 10px 24px 9px 9px;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
	position: relative;
	background: #99A5BE;
	border: 1px solid #99A5BE;
	border-top-color: #A5B2CB;
	color: #4B5468;
	box-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
	width: 200px;

	transition: all 240ms ease-out;
	-webkit-transition: all 240ms ease-out;
	-moz-transition: all 240ms ease-out;
	-ms-transition: all 240ms ease-out;
	-o-transition: all 240ms ease-out;
}

div.fancy-select div.trigger:after {
	content: "";
	display: block;
	position: absolute;
	width: 0;
	height: 0;
	border: 5px solid transparent;
	border-top-color: #4B5468;
	top: 20px;
	right: 9px;
}

div.fancy-select div.trigger.open {
	background: #4A5368;
	border: 1px solid #475062;
	color: #7A8498;
	box-shadow: none;
}

div.fancy-select div.trigger.open:after {
	border-top-color: #7A8498;
}

div.fancy-select ul.options {
	list-style: none;
	margin: 0;
	position: absolute;
	top: 40px;
	left: 0;
	visibility: hidden;
	opacity: 0;
	z-index: 50;
	max-height: 200px;
	overflow: auto;
	background: #62C8BF;
	border-radius: 4px;
	border-top: 1px solid #7DD8D2;
	box-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
	min-width: 200px;

	transition: opacity 300ms ease-out, top 300ms ease-out, visibility 300ms ease-out;
	-webkit-transition: opacity 300ms ease-out, top 300ms ease-out, visibility 300ms ease-out;
	-moz-transition: opacity 300ms ease-out, top 300ms ease-out, visibility 300ms ease-out;
	-ms-transition: opacity 300ms ease-out, top 300ms ease-out, visibility 300ms ease-out;
	-o-transition: opacity 300ms ease-out, top 300ms ease-out, visibility 300ms ease-out;
}

div.fancy-select ul.options.open {
	visibility: visible;
	top: 50px;
	opacity: 1;

	/* have to use a non-visibility transition to prevent this iOS issue (bug?): */
	/*http://stackoverflow.com/questions/10736478/css-animation-visibility-visible-works-on-chrome-and-safari-but-not-on-ios*/
	transition: opacity 300ms ease-out, top 300ms ease-out;
	-webkit-transition: opacity 300ms ease-out, top 300ms ease-out;
	-moz-transition: opacity 300ms ease-out, top 300ms ease-out;
	-ms-transition: opacity 300ms ease-out, top 300ms ease-out;
	-o-transition: opacity 300ms ease-out, top 300ms ease-out;
}

div.fancy-select ul.options.overflowing {
	top: auto;
	bottom: 40px;

	transition: opacity 300ms ease-out, bottom 300ms ease-out, visibility 300ms ease-out;
	-webkit-transition: opacity 300ms ease-out, bottom 300ms ease-out, visibility 300ms ease-out;
	-moz-transition: opacity 300ms ease-out, bottom 300ms ease-out, visibility 300ms ease-out;
	-ms-transition: opacity 300ms ease-out, bottom 300ms ease-out, visibility 300ms ease-out;
	-o-transition: opacity 300ms ease-out, bottom 300ms ease-out, visibility 300ms ease-out;
}

div.fancy-select ul.options.overflowing.open {
	top: auto;
	bottom: 50px;

	transition: opacity 300ms ease-out, bottom 300ms ease-out;
	-webkit-transition: opacity 300ms ease-out, bottom 300ms ease-out;
	-moz-transition: opacity 300ms ease-out, bottom 300ms ease-out;
	-ms-transition: opacity 300ms ease-out, bottom 300ms ease-out;
	-o-transition: opacity 300ms ease-out, bottom 300ms ease-out;
}

div.fancy-select ul.options li {
	padding: 8px 12px;
	color: #2B8686;
	cursor: pointer;
	white-space: nowrap;

	transition: all 150ms ease-out;
	-webkit-transition: all 150ms ease-out;
	-moz-transition: all 150ms ease-out;
	-ms-transition: all 150ms ease-out;
	-o-transition: all 150ms ease-out;
}

div.fancy-select ul.options li.selected {
	background: rgba(43,134,134,0.3);
	color: rgba(255,255,255,0.75);
}

div.fancy-select ul.options li.hover {
	color: #fff;
}