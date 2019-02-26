# MockEverything
The **MockEvertyhing** is a framework to mock functions and procedures during the process of unit testing. It was created based on the DDetours Library
and provides an easy way to mock methods including constructors and destructors.


## Features: ##
* Support for x86
* Special functions to mock all the methods.
* Support to mock constructor and destructor.
* Support to mock private and protected methods via mapfile.
* Easy access to private and protected fields and properties via Rtti.
* Easy way to restore the original method behavior.

## Roadmap: ##

* Add a custom unit test
* Add a custom Exception class
* Support for x64
* Port for Lazarus FPC


## Dependencies: ##

* [DDetours](https://github.com/MahdiSafsafi/DDetours)

## How to use: ##

* Add the DDetours in your project
* Use the unit MockEverything
* May you want add also the MockRttiUtils
* Enjoy 

## Tips: ##

* Use the TMockDetour.Get.RestoreEverything in the TearDown to restore the original behavior of the class.
* Load the MapFile just once, usually before the Application.Run.
* Avoid use TMockDetour.Get.MockEvertyhing in huge classes, it can be slow.
* It's impossible to mock automatically methods private and protected, except when it was explicitly exported via Rtti.

The library was tested under the Delphi Seattle and Tokyo using DUnit and DUnitX.
Please, if you find any bug, feel free to report it.
