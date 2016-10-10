# Custom Capability Matcher
Example that shows how to implement a Selenium Grid capability matcher, implementation of a tutorial that can be
found [here](https://rationaleemotions.wordpress.com/2014/01/19/working-with-a-custom-capability-matcher-in-the-grid/).

## How to generate the jar
_It will be placed in the target folder_
```
    $ mvn -DskipTests=true package
```

## Steps to start the grid
1. Download Selenium Server

  ```
    $ wget http://selenium-release.storage.googleapis.com/2.53/selenium-server-standalone-2.53.0.jar
  ```
1. Start the hub with a the specific configuration

  ```
    $ java -cp selenium-server-standalone-2.53.0.jar:target/custom-capability-matcher-1.0-SNAPSHOT.jar org.openqa.grid.selenium.GridLauncher -role hub -hubConfig src/main/resources/hubConfig.json
  ```
1. Start the `foo` node

  ```
    $ java -jar selenium-server-standalone-2.53.0.jar -role node -hub http://localhost:4444/grid/register -nodeConfig src/main/resources/nodeConfig_foo.json
  ```
1. Start the `bar` node

  ```
    $ java -jar selenium-server-standalone-2.53.0.jar -role node -hub http://localhost:4444/grid/register -nodeConfig src/main/resources/nodeConfig_bar.json
  ```
  
## Run the test 
```
  $ mvn test
```
Change this [line](https://github.com/diemol/custom-capability-matcher/blob/master/src/test/java/SampleCapabilityMatcherTest.java#L17) to see the matcher in action by:
* Either setting `nodeName` capability to `foo` or `bar` and see the test getting executed in the desired node.
* Removing the `nodeName` capability and letting the `DefaultCapabilityMatcher` decide.
* Or setting `nodeName` to a different value and seeing the Grid reject the request because no node matches the capabilities.


