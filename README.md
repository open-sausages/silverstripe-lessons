<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
* An overview of environments
* Setting up logging on different environments
* Dealing with email

## An overview of environments

So far we've been working on our project only in the context of a development environment, but it's important to consider that we're eventually going to want to deploy to a remote test environment, and hopefully soon after, a production website. A given project can have many environments, especially large projects that are entertaining multiple, concurrent development efforts. Each environment introduces new state, and managing that state can be really cumbersome if you don't have a solid set up. Therefore, it's important to start considering your environments early on in your development process.

We've already talked a bit about the centrepiece of environment management in SilverStripe, the `.env` file. Just as a reminder, this file is intended to reside above the web root to provide environment-specific variables to the project. This allows you to deploy one coherent codebase to each environment without having to write conditional logic to serve each environment. It does introduce the complexity of needing a higher level of write access to your server, however, so you'll want to make sure you have shell access or a highly privileged FTP account that will allow you to edit files above the web root.

## Setting up logging on different environments

One of the services you'll want enabled on test and, even more so, production, is good error logging and notification. In our dev environment, we want to suppress this, as we don't mind getting verbose errors, but once the project is on the web, you'll want to suppress showstopping errors as much as possible and simply log them out so you can proactively fix them.

As of version 4.0, SilverStripe uses the [PSR-3 logging](https://github.com/php-fig/fig-standards/blob/master/accepted/PSR-3-logger-interface.md) standard. This means it is easy to swap out the logger with an alternative implementation, and allows your SilverStripe application to play nicely with other frameworks and libraries.

To log errors, just access the logger interface with Injector.

```php
use SilverStripe\Core\Injector\Injector;
use Psr\Log\LoggerInterface;

Injector::inst()->get(LoggerInterface::class)->error('Description of error');
```

Also available per the PSR-3 standard are:

* `emergency()`
* `alert()`
* `critical()`
* `warning()`
* `notice()`
* `info()`
* `debug()`
* `log()`

For a full list, see the PSR-3 documentation](http://www.php-fig.org/psr/psr-3/).

It's a good idea to throw these in your user code where appropriate. Logging can be very useful for debugging. When using the logger in your classes, you need not keep going through `Injector` to get a logger instance. A cleaner approach is to inject the logger as a dependency.

```php
namespace My\App;

use Psr\Log\LoggerInterface;
use PageController;

class MyPageController extends PageController
{
  private static $dependencies = [
    'logger' => '%$' . LoggerInterface::class
  ];
  
  protected $shouldFail = true;
  
  public $logger;
  
  public function doSomething()
  {
    if ($this->shouldFail) {
      $this->logger->log('It failed');
    }
  }
}
```

What all of these logging methods acutally do depends on the implementation of `LoggerInterface` that you're using. By default, SilverStripe ships with [Monolog](https://github.com/Seldaek/monolog), a logging library that comes with its own PSR-3 logging implementation, `Monolog\Logger`.

The `Monolog\Logger` class supports *handlers*, which must implement their own `HandlerInterface` definition. You can add as many handlers as you like. Some commonly used handlers ship with SilverStripe Framework.

Here's an example of adding an email handler. Any error that happens at or above the given logging level will send an email to an administrator. Let's make anything `error()` and above send an email.

*mysite/_config/logging.yml*
```yml
SilverStripe\Core\Injector\Injector:
  Psr\Log\LoggerInterface: 
    calls:
      EmailHandler: [ pushHandler, [ %$EmailHandler ] ]
  EmailHandler:
      class: Monolog\Handler\NativeMailerHandler
      constructor:
        - errors@example.com
        - Error reported on example.com
        - admin@example.com
        - error
      properties:
        ContentType: text/html
        Formatter: %$SilverStripe\Logging\DetailedErrorFormatter
```

Since email is a pretty aggressive form of error notification, we probably don't want to sent it from anywhere other than the live environment. Let's put this in a conditional block.

*mysite/_config/logging.yml*
```yml
    --- 
    Name: lessons-live-logging
    Only:
      environment: live
    ---
    SilverStripe\Core\Injector\Injector:
     Psr\Log\LoggerInterface: 
      calls:
        EmailHandler: [ pushHandler, [ %$EmailHandler ] ]
    #...
```


A better option for low-level errors is writing to a log file. Let's set that up for anything over `notice()` level.

*mysite/_config/logging.yml*
```yml
    ---
    Name: lessons-all-logging
    ---
    SilverStripe\Core\Injector\Injector:
      Psr\Log\LoggerInterface: 
        calls:
          FileLogger: [ pushHandler, [ %$FileLogger ] ]
      FileLogger:
        class: Monolog\Handler\StreamHandler
        constructor:
          - "../errors.log"
          - "notice"
```

Let's make sure that error log doesn't get checked into our repository by adding it to `.gitignore`.

<<<<<<< HEAD
*.gitignore*
```
...
# ignore error log
errors.log
```

## Dealing with email
=======
So now that we have a good understanding of `ViewableData`, let's play around with some of its features. Right now, we're just returning a string to the template for our Ajax response. Let's instead return a partial template.

At the centre of dealing with Ajax responses is the use of includes in your Layout template. Let's take everything in the `.main` div, and export it to an include called `PropertySearchResults`.

*themes/one-ring/templates/SilverStripe/Lessons/Includes/PropertySearchResults.ss*
```html
<!-- BEGIN MAIN CONTENT -->
<div class="main col-sm-8">
	<% include SilverStripe/Lessons/PropertySearchResults %>				
</div>	
<!-- END MAIN CONTENT -->
=======
## What we'll cover
* What are we working towards?
* Updating the template: Working backwards
* Updating the controller to use generic data
=======
In this lesson we'll talk about filtering a list of items on a template. In a previous tutorial, we looked at filtering through form inputs. Now, we'll explore how to do that through the navigation.
>>>>>>> Begin lesson 19
=======
In the previous tutorial, we activated most of the sidebar filters for our Travel Guides section. We left out the date archive filter, however, because it introduced some complexity. Let's now dive into that complexity and get it working.
>>>>>>> Begin lesson 20

### Adding date filter links to the template

Looking at the template, we first have to generate a list of all the distinct month/year combinations for all the articles. Let's start by working backwards, and we want the end result to be on the template.

*themes/one-ring/templates/SilverStripe/Lessons/Layout/ArticleHolder.ss*
```html
  <!-- BEGIN ARCHIVES ACCORDION -->
	<h2 class="section-title">Archives</h2>
	<div id="accordion" class="panel-group blog-accordion">
		<div class="panel">
		<!--
			<div class="panel-heading">
				<div class="panel-title">
					<a data-toggle="collapse" data-parent="#accordion" href="#collapseOne" class="">
						<i class="fa fa-chevron-right"></i> 2014 (15)
					</a>
				</div>
			</div>
		-->
			<div id="collapseOne" class="panel-collapse collapse in">
				<div class="panel-body">
					<ul>
					<% loop $ArchiveDates %>
						<li><a href="$Link">$MonthName $Year ($ArticleCount)</a></li>
					<% end_loop %>
					</ul>
				</div>
			</div>
		</div>	
	</div>
	<!-- END  ARCHIVES ACCORDION -->
=======
* An overview of environments
* Setting up logging on different environments
* Dealing with email
>>>>>>> Begin lesson 21

## An overview of environments

So far we've been working on our project only in the context of a development environment, but it's important to consider that we're eventually going to want to deploy to a remote test environment, and hopefully soon after, a production website. A given project can have many environments, especially large projects that are entertaining multiple, concurrent development efforts. Each environment introduces new state, and managing that state can be really cumbersome if you don't have a solid set up. Therefore, it's important to start considering your environments early on in your development process.

We've already talked a bit about the centrepiece of environment management in SilverStripe, the `.env` file. Just as a reminder, this file is intended to reside above the web root to provide environment-specific variables to the project. This allows you to deploy one coherent codebase to each environment without having to write conditional logic to serve each environment. It does introduce the complexity of needing a higher level of write access to your server, however, so you'll want to make sure you have shell access or a highly privileged FTP account that will allow you to edit files above the web root.

## Setting up logging on different environments

One of the services you'll want enabled on test and, even more so, production, is good error logging and notification. In our dev environment, we want to suppress this, as we don't mind getting verbose errors, but once the project is on the web, you'll want to suppress showstopping errors as much as possible and simply log them out so you can proactively fix them.

As of version 4.0, SilverStripe uses the [PSR-3 logging](https://github.com/php-fig/fig-standards/blob/master/accepted/PSR-3-logger-interface.md) standard. This means it is easy to swap out the logger with an alternative implementation, and allows your SilverStripe application to play nicely with other frameworks and libraries.

To log errors, just access the logger interface with Injector.

```php
use SilverStripe\Core\Injector\Injector;
use Psr\Log\LoggerInterface;

Injector::inst()->get(LoggerInterface::class)->error('Description of error');
```

Also available per the PSR-3 standard are:

* `emergency()`
* `alert()`
* `critical()`
* `warning()`
* `notice()`
* `info()`
* `debug()`
* `log()`

For a full list, see the PSR-3 documentation](http://www.php-fig.org/psr/psr-3/).

It's a good idea to throw these in your user code where appropriate. Logging can be very useful for debugging. When using the logger in your classes, you need not keep going through `Injector` to get a logger instance. A cleaner approach is to inject the logger as a dependency.

```php
<<<<<<< HEAD
		if ($result) {
			while($record = $result->nextRecord()) {
				list($year, $monthName, $monthNumber) = explode('_', $record['DateString']);

				$list->push(ArrayData::create([
					'Year' => $year,
					'MonthName' => $monthName,
					'MonthNumber' => $monthNumber,
					'Link' => $this->Link("date/$year/$monthNumber"),
					'ArticleCount' => ArticlePage::get()->where([
							"DATE_FORMAT(\"Date\",'%Y_%m')" => "{$year}_{$monthNumber}",
							"\"ParentID\"" => $this->ID
						])->count()
				]));
			}
		}
<<<<<<< HEAD
	}
<<<<<<< HEAD
	//...
>>>>>>> Begin lesson 18
=======
  //...
>>>>>>> Begin lesson 19
=======
>>>>>>> Begin lesson 20
```

We loop through each record using the `nextRecord()` method. For each record, we explode the SKU into its component variables -- the year, the month number, and the month name -- and assign them to properties of an `ArrayData` object. We also create a link to the `date/$year/$monthNumber` route that we created in `ArticleHolder`. Lastly, we run a query against `ArticlePage` to get the number of articles that match this date SKU. Notice that in this case, we can safely just match the year and month number.

Notice that the `where()` method affords us parameterised queries. The shorthand of `'fieldName' => 'value'` should be used whenever possible to ensure your queries are safe from injection.

Here's the complete `ArchiveDates()` function:

*mysite/code/ArticleHolder.php*
```php
	public function ArchiveDates()
	{
		$list = ArrayList::create();
		$stage = Versioned::get_stage();		
    $baseTable = ArticlePage::getSchema()->tableName(ArticlePage::class);
    $tableName = $stage === Versioned::LIVE ? "{$baseTable}_Live" : $baseTable;

    $query = SQLSelect::create()
        ->setSelect([])
        ->selectField("DATE_FORMAT(`Date`,'%Y_%M_%m')", "DateString")
        ->setFrom($tableName)
        ->setOrderBy("DateString", "ASC")
        ->setDistinct(true);

    $result = $query->execute();
		
		if ($result) {
			while($record = $result->nextRecord()) {
				list($year, $monthName, $monthNumber) = explode('_', $record['DateString']);

				$list->push(ArrayData::create([
					'Year' => $year,
					'MonthName' => $monthName,
					'MonthNumber' => $monthNumber,
					'Link' => $this->Link("date/$year/$monthNumber"),
					'ArticleCount' => ArticlePage::get()->where([
							"DATE_FORMAT(\"Date\",'%Y_%m')" => "{$year}_{$monthNumber}",
							"\"ParentID\"" => $this->ID
						])->count()
				]));
			}
		}
		
		return $list;
```
=======
namespace My\App;
>>>>>>> Begin lesson 21

use Psr\Log\LoggerInterface;
use PageController;

class MyPageController extends PageController
{
  private static $dependencies = [
    'logger' => '%$' . LoggerInterface::class
  ];
  
  protected $shouldFail = true;
  
  public $logger;
  
  public function doSomething()
  {
    if ($this->shouldFail) {
      $this->logger->log('It failed');
    }
  }
}
```

<<<<<<< HEAD
<<<<<<< HEAD
Back in the template, change the `<% loop %>` block to use the `$PaginatedArticles` method.

*themes/one-ring/templates/SilverStripe/Lessons/Layout/ArticleHolder.ss*
```html
	<div id="blog-listing" class="list-style clearfix">
		<div class="row">
			<% loop $PaginatedArticles %>
			<div class="item col-md-6">
			<!-- .... -->
			</div>
			<% end_loop %>
```

<<<<<<< HEAD
<<<<<<< HEAD
* Assign `$paginatedProperties` to a public property on the controller
* Explicitly pass it to the template using `customise()`.
>>>>>>> Lesson 17 complete

While we're on the topic of email, let's take some control over transactional emails in our environments. This can be a really annoying problem for a couple of reasons. For one, if we're testing with real data, we don't want transactional emails to be sent to real users from our development environment. Second, we want to be able to test whether those emails would be sent, and what their contents would be if we were in production.

A simple solution to this problem is to simply force the "to" address to go to you in the dev environment. You can configure this in the config yaml.

<<<<<<< HEAD
*mysite/_config/config.yml*
```yaml
Email:
  send_all_emails_to: 'me@example.com'
=======
=======
The next filter is for the availability date range. It actually doesn't offer a whole lot of utility to the user to display this as a toggleable filter, especially since it's actually a composite filter of `ArrivalDate` and `Nights`, so let's skip this one.
=======
For now, let's borrow the pagination HTML from the `PropertySearchResults.ss` file. If you're boiling inside about DRY violations, relax. We'll address this duplication in an upcoming lesson.
>>>>>>> Begin lesson 19

Take a deep breath, and copy and paste away. No one will know. Just make sure you change `$Results` to `$PaginatedArticles`.

*themes/one-ring/templates/SilverStripe/Lessons/Layout/ArticleHolder.ss*
```html
	<!-- BEGIN PAGINATION -->
	<% if $PaginatedArticles.MoreThanOnePage %>
	<div class="pagination">
		<% if $PaginatedArticles.NotFirstPage %>
		<ul id="previous col-xs-6">
			<li><a href="$PaginatedArticles.PrevLink"><i class="fa fa-chevron-left"></i></a></li>
		</ul>
		<% end_if %>
		<ul class="hidden-xs">
			<% loop $PaginatedArticles.PaginationSummary %>
				<% if $Link %>
					<li <% if $CurrentBool %>class="active"<% end_if %>>
						<a href="$Link">$PageNum</a>
					</li>
				<% else %>
					<li>...</li>
				<% end_if %>
			<% end_loop %>
		</ul>
		<% if $PaginatedArticles.NotLastPage %>
		<ul id="next col-xs-6">
			<li><a href="$PaginatedArticles.NextLink"><i class="fa fa-chevron-right"></i></a></li>
		</ul>
		<% end_if %>
	</div>
	<% end_if %>
	<!-- END PAGINATION -->
```
=======
We'll start by running a sanity check to ensure that we at least have a year in the URL. Then, we'll create a start date of either the first of the month or the first of the year. If for some reason the year or month values are invalid, and don't pass the `strtotime()` test, we throw an HTTP error.
>>>>>>> Begin lesson 20

Now, we'll create the boundary for the end date, and run the query.

*mysite/code/ArticleHolderController.php*
```php
<<<<<<< HEAD
<<<<<<< HEAD
>>>>>>> Begin lesson 18
	public function index(HTTPRequest $request)
=======
use SilverStripe\Control\HTTPRequest;

class ArticleHolderController extends PageController
{
	
	//...
	public function category (HTTPRequest $r)
>>>>>>> Begin lesson 19
	{
		$category = ArticleCategory::get()->byID(
			$r->param('ID')
		);

<<<<<<< HEAD
<<<<<<< HEAD
		if ($bedrooms = $request->getVar('Bedrooms')) {
			$filters->push(ArrayData::create([
				'Label' => "$bedrooms bedrooms",
				'RemoveLink' => HTTP::setGetVar('Bedrooms', null)
			]));

			$properties = $properties->filter([
				'Bedrooms:GreaterThanOrEqual' => $bedrooms
			]);
		}

<<<<<<< HEAD
		return [
			'Results' => $paginatedProperties
		];
	}
}
>>>>>>> Lesson 17 complete
```

<<<<<<< HEAD
Pretty straightforward, but we're forgetting something. We don't want this setting to apply to all environments. We need to ensure that this yaml is only loaded in the dev environment. We're not writing PHP, so we don't have the convenience of if/else blocks, but fortunately, the SilverStripe YAML parser affords us a basic API for conditional logic.

*mysite/_config/email.yml*
```yaml
    ---
    Name: dev-email
    Only:
      environment: dev
    ---
    Email:
      send_all_emails_to: 'me@example.com'
```

Perhaps in the test and production environments, we want to monitor transactional email from a bit of a distance. We could force a BCC to our email address in that case.

*mysite/_config/email.yml*
```yaml
    ---
    Name: dev-email
    Only:
      environment: dev
    ---
    Email:
      send_all_emails_to: 'me@example.com'
    ---
    Name: live-email
    Except:
      environment: dev
    ---
    Email:
      bcc_all_emails_to: 'me@example.com'
=======
=======
		if ($bathrooms = $request->getVar('Bathrooms')) {
			$filters->push(ArrayData::create([
				'Label' => "$bathrooms bathrooms",
				'RemoveLink' => HTTP::setGetVar('Bathrooms', null)
			]));

			$properties = $properties->filter([
				'Bathrooms:GreaterThanOrEqual' => $bathrooms
			]);
		}

		if ($minPrice = $request->getVar('MinPrice')) {
			$filters->push(ArrayData::create([
				'Label' => "Min. \$$minPrice",
				'RemoveLink' => HTTP::setGetVar('MinPrice', null)
			]));
>>>>>>> Begin lesson 18

			$properties = $properties->filter([
				'PricePerNight:GreaterThanOrEqual' => $minPrice
			]);
		}

		if ($maxPrice = $request->getVar('MaxPrice')) {
			$filters->push(ArrayData::create([
				'Label' => "Max. \$$maxPrice",
				'RemoveLink' => HTTP::setGetVar('MaxPrice', null)
			]));

			$properties = $properties->filter([
				'PricePerNight:LessThanOrEqual' => $maxPrice
			]);
		}
=======
    $filters = [
        ['Bedrooms', 'Bedrooms', 'GreaterThanOrEqual', '%s bedrooms'],
        ['Bathrooms', 'Bathrooms', 'GreaterThanOrEqual', '%s bathrooms'],
        ['MinPrice', 'PricePerNight', 'GreaterThanOrEqual', 'Min. $%s'],
        ['MaxPrice', 'PricePerNight', 'LessThanOrEqual', 'Max. $%s'],
    ];

    foreach($filters as $filterKeys) {
        list($getVar, $field, $filter, $labelTemplate) = $filterKeys;
        if ($value = $request->getVar($getVar)) {
            $activeFilters->push(ArrayData::create([
                'Label' => sprintf($labelTemplate, $value),
                'RemoveLink' => HTTP::setGetVar($getVar, null, null, '&'),
            ]));

            $properties = $properties->filter([
                "{$field}:{$filter}" => $value
            ]);
        }
    }
>>>>>>> Lesson 18 complete
=======
		if(!$category) {
			return $this->httpError(404,'That category was not found');
		}
>>>>>>> Begin lesson 19
=======
		$adder = $month ? '+1 month' : '+1 year';
		$endDate = date('Y-m-d', strtotime(
		    $adder, 
				strtotime($startDate)
		));
>>>>>>> Begin lesson 20

		$this->articleList = $this->articleList->filter([
			'Date:GreaterThanOrEqual' => $startDate,
			'Date:LessThan' => $endDate 
		]);

		return [
			'StartDate' => DBField::create_field('Datetime', $startDate),
			'EndDate' => DBField::create_field('Datetime', $endDate)
		];
```

<<<<<<< HEAD
We start first by checking if the category exists. If not, we throw a 404. Then, we update the article list by filtering the current one against the `many_many` relation, `Categories`. This is a wonderful example of the power of the ORM. Its abstraction layer allows us to filter by a parameter that is not necessarily a field in the database, but rather, a named relationship in our code. The filter `Categories.ID => $category->ID` simply asks for all the articles that contain the given category ID in their list of their related category IDs.

<<<<<<< HEAD
<<<<<<< HEAD
>>>>>>> Lesson 17 complete
```

This works okay, but it's kind of broad. If we have other developers on the project, they're not going to get any emails, and we also can't accurately test from our dev environment what the "to" address would actually be in production or test.

### MailCatcher

A much more thorough solution is to use a thirdparty tool to capture outgoing emails from your dev environment. There are a few of these tools available, but the one I like, and recommend, is [MailCatcher](https://mailcatcher.me/). Follow the instructions on the home page to install the software, and with just a bit of configuration, you can pipe all email into a local inbox. To browse the inbox, simply visit localhost:1080. Now, you can monitor all outgoing emails, and know exactly who would receive them and what their contents would be in a production environment.
=======
Just like our custom variable `Results`, we'll pass the `ActiveFilters` list to the template through an array.
=======
At the end of the function, we return the selected category to the template. This will be important when adding text to the page that shows the filtered state.
>>>>>>> Begin lesson 19
=======
A really key detail of this function is that we return proper `SilverStripe\ORM\FieldType\DBField` objects to the template. If you'll remember from the early tutorials, controllers don't just return scalar values to the template. They're actually first-class, intelligent objects. By default, they're cast as `Text` objects, so we'll be more explicit and ensure that `StartDate` and `EndDate` are cast as dates. This will afford us the option to format them on the template.
>>>>>>> Begin lesson 20

You can achieve the same result more declaratively using the `$casting` setting on in your controller. We'll discuss that in a future tutorial and clean this up a bit.

For now, here is the complete `date()` controller action:

*mysite/code/ArticleHolderController.php*
```php
//...
use SilverStripe\ORM\FieldType\DBField;

class ArticleHolderController extends PageController
{
	
	//...
=======
What all of these logging methods acutally do depends on the implementation of `LoggerInterface` that you're using. By default, SilverStripe ships with [Monolog](https://github.com/Seldaek/monolog), a logging library that comes with its own PSR-3 logging implementation, `Monolog\Logger`.

The `Monolog\Logger` class supports *handlers*, which must implement their own `HandlerInterface` definition. You can add as many handlers as you like. Some commonly used handlers ship with SilverStripe Framework.

Here's an example of adding an email handler. Any error that happens at or above the given logging level will send an email to an administrator. Let's make anything `error()` and above send an email.

*mysite/_config/logging.yml*
```yml
SilverStripe\Core\Injector\Injector:
  Psr\Log\LoggerInterface: 
    calls:
      EmailHandler: [ pushHandler, [ %$EmailHandler ] ]
  EmailHandler:
      class: Monolog\Handler\NativeMailerHandler
      constructor:
        - errors@example.com
        - Error reported on example.com
        - admin@example.com
        - error
      properties:
        ContentType: text/html
        Formatter: %$SilverStripe\Logging\DetailedErrorFormatter
```

Since email is a pretty agressive form of error notification, we probably don't want to sent it from anywhere other than the live environment. Let's put this in a conditional block.

*mysite/_config/logging.yml*
```yml
    --- 
    Name: live-logging
    Only:
      environment: live
    ---
    SilverStripe\Core\Injector\Injector:
     Psr\Log\LoggerInterface: 
      calls:
        EmailHandler: [ pushHandler, [ %$EmailHandler ] ]
    #...
```
>>>>>>> Begin lesson 21


A better option for low-level errors is writing to a log file. Let's set that up for anything over `notice()` level.

*mysite/_config/logging.yml*
```yml
SilverStripe\Core\Injector\Injector:
  Psr\Log\LoggerInterface: 
    calls:
      FileLogger: [ pushHandler, [ %$FileLogger ] ]
  FileLogger:
    class: Monolog\Handler\StreamHandler
    constructor:
      - "../errors.log"
      - "notice"
```


## Dealing with email

While we're on the topic of email, let's take some control over transactional emails in our environments. This can be a really annoying problem for a couple of reasons. For one, if we're testing with real data, we don't want transactional emails to be sent to real users from our development environment. Second, we want to be able to test whether those emails would be sent, and what their contents would be if we were in production.

A simple solution to this problem is to simply force the "to" address to go to you in the dev environment. You can configure this in the config yaml.

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
Reload the page, and you should have working filter buttons now!
>>>>>>> Begin lesson 18
=======
Test the regions filter in your browser and see that it's working.
=======
	//...
=======
*mysite/_config/config.yml*
```yaml
Email:
  send_all_emails_to: 'me@example.com'
>>>>>>> Begin lesson 21
```
>>>>>>> Begin lesson 20

Pretty straightforward, but we're forgetting something. We don't want this setting to apply to all environments. We need to ensure that this yaml is only loaded in the dev environment. We're not writing PHP, so we don't have the convenience of if/else blocks, but fortunately, the SilverStripe YAML parser affords us a basic API for conditional logic.

*mysite/_config/config.yml*
```yaml
    ---
    Name: dev-email
    Only:
      environment: dev
    ---
    Email:
      send_all_emails_to: 'me@example.com'
```

Perhaps in the test and production environments, we want to monitor transactional email from a bit of a distance. We could force a BCC to our email address in that case.

*mysite/_config/config.yml*
```yaml
    ---
    Name: dev-email
    Only:
      environment: dev
    ---
    Email:
      send_all_emails_to: 'me@example.com'
    ---
    Name: live-email
    Except:
      environment: dev
    ---
    Email:
      bcc_all_emails_to: 'me@example.com'
```

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
One missing piece you'll notice is that the detail page still has a static sidebar. Getting this to work requires teaching a new concept, and we'll address that in the next couple of lessons.
>>>>>>> Begin lesson 19
=======
This is where having proper `SilverStripe\ORM\FieldType\Datetime` objects comes in really handy, as we can format the date right on the template.
>>>>>>> Begin lesson 20
=======
We'll also add the dates to the articles themselves, removing the static dates that are there now.
=======
This works okay, but it's kind of broad. If we have other developers on the project, they're not going to get any emails, and we also can't accurately test from our dev environment what the "to" address would actually be in production or test.
>>>>>>> Begin lesson 21

### MailCatcher

<<<<<<< HEAD
This is where having proper `SilverStripe\ORM\FieldType\Datetime` objects comes in really handy, as we can format the date right on the template.
>>>>>>> Lesson 20 complete
=======
A much more thorough solution is to use a thirdparty tool to capture outgoing emails from your dev environment. There are a few of these tools available, but the one I like, and recommend, is [MailCatcher](https://mailcatcher.me/). Follow the instructions on the home page to install the software, and with just a bit of configuration, you can pipe all email into a local inbox. To browse the inbox, simply visit localhost:1080. Now, you can monitor all outgoing emails, and know exactly who would receive them and what their contents would be in a production environment.
>>>>>>> Begin lesson 21
