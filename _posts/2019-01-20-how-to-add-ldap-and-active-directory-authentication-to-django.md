---
layout: post
title: How to add LDAP & Active Directory Authentication to Django
date: 2019-01-20 00:00:00 +0000
categories: docker
permalink: /@marcus/how-to-add-ldap-and-active-directory-authentication-to-django/
---

You know that you're working for an Enterprise business when you're asked to integrate their website's authentication with their Active Directory server. If you have no idea what Active Directory is, don't worry it probably just means that you're living within the StartUp bubble of web development!

Active Directory is Microsoft's enterprise solution for storing user data. Many enterprises use it as a centralized location of all their employees data where they can easily update passwords, information and permissions from a single location, and then due to integrations with most of the software they use, they can easily control access throughout their whole organization.

When you're working with Django you might often be asked to [add social authentication](https://coderbook.com/@marcus/how-to-add-social-authentication-to-django/) to the website so that users can login with their Facebook or Google account. There is a done of information and documentation out there for these type of integrations since they are so common, but what about integrating with Active Directory?

Even though its a very popular way for enterprise business to handle user data, because of the type of businesses that do this it is naturally not as common, and there is not that much resources out there of how you implement this with Django.

## Introduction to Active Directory and LDAP
Active Directory (AD) exist on most implementations of Windows Server and the summary of what it is, is that its basically just a "Directory Service" for different type of identification and authentication data. This implies that you can store more than just user data within AD, but one of the core use cases of it is to store and manage users data and permissions.

AD use LDAP (Lightweight Directory Access Protocol) for communication, so this is the protocol used whenever we want to send or query data within AD. More on that later.

As mentioned within the introduction of this article, Active Directory is rarely used within Startup environments and is mainly something used for enterprise businesses with a lot of user data that they want to centralize and easily manage in a single location. This is not as crucial for a company with a few dozen employees where user management can be tolerable in less centralized and efficient ways.

If you plan to work with large companies, you should definitely look into AD and LDAP since it will definitely come up and its important that you have an answer to how you would implement it for new websites, services or applications that you will build for them.

## Install Django Auth LDAP
[django-auth-ldap](https://github.com/django-auth-ldap/django-auth-ldap) is a great package that offer some core functionality required for implementing authentication with Active Directory over the LDAP protocol in Django. All it requires us to do is installing it and its dependencies, and then add required configuration to our `settings.py` file, and it will work out of the box without requiring any additional integrations with our application.

Unlike most Django packages that you install over `pip`, the `django-auth-ldap` package require us to install some system dependencies for it to work. Because of this I recommend you to use [Docker](https://docker.com) to create a `Dockerfile` that allows you to explicitly define the system dependencies required for your application to run.

This is not required, but it makes sure that you always have the same system dependencies installed both on your Development environment and your Production environment after you've deployed your application.

The system dependencies required for Ubuntu/Debian are the following:

- `libldap2-dev`
- `libsasl2-dev`
- `slapd`
- `ldap-utils`

In my own case I install it in my `Dockerfile` using the following command:

```dockerfile
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y  libldap2-dev libsasl2-dev slapd ldap-utils
```

After you've installed the required system dependencies you can then install the django package using:

```bash
# Note that a more recent version might be out when you're 
# reading this article.
pip install django-auth-ldap==1.7.0
```

## Configure Django Auth LDAP
After we've installed the package and its dependencies we are ready to configure it to work the way we want to, and to integrate with our specific Active Directory instance. Unlike many other Django packages, `django-auth-ldap` **do not** need you to add it to your application's `INSTALLED_APPS` setting.

The first thing we need to do is to add the LDAP Backend to our `AUTHENTICATION_BACKENDS` setting. Note that this custom backend does not extend the traditional `ModelBackend` so if you still want to support traditional Django users and authentication, you should leave this one in.

```python
AUTHENTICATION_BACKENDS = [
    "django.contrib.auth.backends.ModelBackend",
    "django_auth_ldap.backend.LDAPBackend",
]
```

Note that the order of the backends matter. By specifying the `ModelBackend` first in the list, it means that authentication requests will first attempt to authenticate towards our database, and after that try to authenticate using LDAP towards our Active Directory instance.

The next step is to configure the package specific settings that defines how we query Active Directory to find the user data.

```python
import ldap
from django_auth_ldap.config import LDAPSearch

AUTH_LDAP_SERVER_URI = os.environ.get("LDAP_HOST")
AUTH_LDAP_ALWAYS_UPDATE_USER = True
AUTH_LDAP_BIND_DN = os.environ.get("LDAP_USERNAME")
AUTH_LDAP_BIND_PASSWORD = os.environ.get("LDAP_PASSWORD")
AUTH_LDAP_USER_SEARCH = LDAPSearch(
    "ou=mybiz,dc=mybiz,dc=com", ldap.SCORE.SUBTREE, "sAMAccountName=%(user)s"
)
AUTH_LDAP_USER_ATTR_MAP = {
    "username": "sAMAccountName",
    "first_name": "givenName",
    "last_name": "sn",
    "email": "mail",
}
```

Lets go through all of this together shall we?

- `AUTH_LDAP_SERVER_URI` is the host that we will send our LDAP requests to, this is the Active Directory host that contain all of our data. For example the value could be `ldap://ldap.coderbook.com`. Note that we use the `ldap://` protocol.
- `AUTH_LDAP_ALWAYS_UPDATE_USER` is a boolean value that determine if Django should update the existing user data it has each time the user login. For example if this value would be set to `False`, it would mean that the first time the user login, our application would store the user settings such as Email or Permissions, but it would never attempt to update this information for future logins of the same user. By setting it to `True` it means that Django will always collect and update the latest information of the user to its database.
- `AUTH_LDAP_BIND_DN` is the username of the credentials required for us to query our Active Directory. This could simply be your personal username, but I would recommend you to setup a dedicated "integrations" user to do this.
- `AUTH_LDAP_BIND_PASSWORD` is the password of the `AUTH_LDAP_BIND_DN` username. This is part of the credentials required to be allowed to query the Active Directory data.
- `AUTH_LDAP_USER_SEARCH` defines the search query that will be used to lookup the user's username and password whenever they attempt to login using the Django login form. See more of this in a paragraph below.
- `AUTH_LDAP_USER_ATTR_MAP` is a mapping between Django User Model values and the values that exist within Active Directory. This is what tells Django which field represents the user's email, username, name etc. Note that this only support the standard Django user fields, you cannot map Active Directory values to custom Django fields using this method.

Regarding the `AUTH_LDAP_USER_SEARCH` setting. This is what defines how Django will query your Active Directory and lookup the username and password provided from the Login Form, to authenticate and validate if those credentials exist.

`LDAPSearch` is a wrapper class that simply allow us to define the search query. The first value is the a way to filter down the rows to the `base_dn` of which users we want to lookup. In our example it means that we will try to authenticate to all users who got the `"ou=mybiz,dc=mybiz,dc=com"` as part of their `dn`.

The second `scope` parameter defines which users from this base that we want to lookup. We use `scope.SUBTREE` to include all users that are part of our `base_dn` subtree.

The final and third parameter is the `filter` value that determines which exact user entry we want to attempt to authenticate to. Here we map the AD `sAMAccountName` value to the supplied `%(user)s` argument, which represents the username that the user input within the Django Login Form.

Note that `sAMAccountName` could be any field and it might not be the right field for you. You need to have a good understanding of the fields defined within your Active Directory user data, to make the proper decision of which field you should use as username.

At this point you should be able to attempt to login using the Django Auth LDAP backend!

### How to add Group Search and Mappings
What if you automatically want to map Django Groups and Permissions to the users that login using LDAP from Active Directory? Perhaps you have some staff that should be considered "Superuser", or maybe you have existing Django Groups that you want to map the users to.

This is quite simple to achieve with the existing `django-auth-ldap` configuration available. Unfortunately if you have more specific permission requirements such as custom `django-guardian` instance level permissions or just traditional Permissions (not by Group) you will have to achieve this by using Signals (See section further down in this article).

In the example below we will map the LDAP Group of the authenticated user to automatically set the `is_superuser` parameter which will give the user full access to our application. All of these values should be added to our `settings.py` file together with the configuration example from our section above.

```python
from django_auth_ldap.config import ActiveDirectoryGroupType


AUTH_LDAP_GROUP_SEARCH = LDAPSearch(
    "ou=mybiz,dc=mybiz,dc=com", ldap.SCOPE_SUBTREE, "(objectCategory=Group)"
)
AUTH_LDAP_GROUP_TYPE = ActiveDirectoryGroupType(name_attr="cn")
AUTH_LDAP_USER_FLAGS_BY_GROUP = {
    "is_superuser": "cn=Management,ou=Super Users Groups,ou=mybiz,dc=mybiz,dc=com",
}
AUTH_LDAP_FIND_GROUP_PERMS = True
AUTH_LDAP_CACHE_GROUPS = True
AUTH_LDAP_GROUP_CACHE_TIMEOUT = 1  # 1 hour cache
```

Let's summarize these settings:

- `AUTH_LDAP_GROUP_SEARCH` is very similar to the previous `AUTH_LDAP_USER_SEARCH` setting that we mentioned in the previous section. This setting allow us to configure the LDAP Query used to lookup the groups that a user is part of within Active Directory.
- `AUTH_LDAP_GROUP_TYPE` defines the class of what type of group we are querying and which format the data is returned in. Since we are querying Active Directory we use the `ActiveDirectoryGroupType` where we specify the `name_attr` as the field of the data that contain the Group Name.
-  `AUTH_LDAP_FIND_GROUP_PERMS` is a boolean value that determines if the user should even attempt to find the groups. This is basically what activates the functionality that we're trying to describe in this section.
-  `AUTH_LDAP_CACHE_GROUPS` activates cache of the user's groups and avoid repeating queries over and over again. Remember that if you enable this, it means that there will be a delay from when you unassign a user from a group within Active Directory, and the user lose those permissions within your Django application.
-  `AUTH_LDAP_GROUP_CACHE_TIMEOUT` determines how long the user's groups will be cached. 

## How add custom data with Django LDAP Auth
In the previous section we described how you can map Active Directory groups to your Django Groups. This will allow you to sort users into different groups with different permissions that have different unique access to your application.

But what if the permission system of your application is more complicated than that? What if you use `django-guardian` to give object level permissions, or what if for some reason you're not using Groups but you want specific users to have some specific permissions?

You can't achieve this by just setting some settings within your `settings.py` file, however you can do it by using Django Signals and hooking into the LDAP Response!

By creating a `signals.py` file within your application that include the following code, you can access the raw LDAP User data and then manually conduct some type of action.

In our example, imagine that users belong to groups such as `Staff Sweden`, `Staff Thailand`, `Staff USA`. Maybe you want all of them to be part of the `Staff` Group, but you also want each of them to belong to a specific market that you have added to your custom Django User model.

```python
import re
from django.dispatch import receiver
from django_auth_ldap.backend import populate_user, LDAPBackend


@receiver(populate_user, sender=LDAPBackend)
def ldap_auth_handler(user, ldap_user, **kwargs):
    """
    Django Signal handler that assign user to Group and Market.
    
    This signal gets called after Django Auth LDAP Package have populated
    the user with its data, but before the user is saved to the database.
    """
    # Check all of the user's group names to see if they belong
    # in a group that match what we're looking for.
    for group_name in ldap_user.group_names:
            match = re.match(r"^Staff ([\w\d\s-]+)$", group_name)
        if match is None:
            continue
        
        # Store the market name, e.g. "USA"
        market_name = match.group(1).strip()
        group_name = "Staff"
        
        # Since this signal is called BEFORE the user object is saved to the database,
        # we have to save it first so that we then can assign groups to it.
        user.save()
        
        # Add user to the Staff Django group.
        group = Group.objects.get(name=group_name)
        user.grous.add(group)
        
        try:
            market = Market.objects.get(name=market_name)
            user.markets.add(market)
        except ObjectDoesNotExist:
            logger.error(f"Attempted to add user to market {market_name} that doesnt exist")
```

Voila, there we have a complete example of how we can access the LDAP data within our Django Signal and then do some kind of custom action to it. In this case as you can see, we try to find out if the user belong to a "Staff" group and then add them to the group but also map them to the correct Market.

If you were using Django Guardians to do instance level permissions based on which market the user belongs to, you could then add another signal using the `m2m_changed` receiver to then add the object level permissions to the user and the updated `Market`.
