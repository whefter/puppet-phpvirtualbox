# puppet-phpvirtualbox

This is a simple module to allow the automated deployment of phpVirtualBox instances.

Internally, the module downloads and unpacks the package from phpVirtualBox's site.

It can also install and set up Apache2 with PHP5 and create virtual hosts as needed. Note that this might conflict with other Apache2/PHP installations on the same machine.

A very basic example could be:


```puppet
include phpvirtualbox

phpvirtualbox::instance { 'srv01':
	httpd => false,
	version => '5.0-5',
	www_owner => 'www-data',
	www_group => 'www-data',
	hosts => {
		'srv01' => {
		    host_name: 'srv01.local',
			username: 'vboxweb',
			password: 'secret',
			location: 'http://srv01.local:18083',
			auth_master: true,
		},
	},
}
```

This will set up a phpVirtualBox instance using the version 5.0-5 source code, but not create a virtualhost. The configuration will include the host entry with the specified parameters, so the `vboxweb-service` service will have to be up and running on `srv01.local` and allow the specified user to login.

For more parameters, especially when using `httpd => true`, see `manifests/instance.pp`.
