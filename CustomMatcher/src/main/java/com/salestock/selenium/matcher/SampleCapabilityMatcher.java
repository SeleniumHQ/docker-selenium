package com.salestock.selenium.matcher;

import org.openqa.grid.internal.utils.DefaultCapabilityMatcher;

import java.util.Map;

public class SampleCapabilityMatcher extends DefaultCapabilityMatcher {

    @Override
    public boolean matches(Map<String, Object> nodeCapability, Map<String, Object> requestedCapability) {

        String nodeName = "nodeName";

        boolean basicChecks = super.matches(nodeCapability, requestedCapability);

        // If the request does not have the special capability, we return what the DefaultCapabilityMatcher returns
        if (!requestedCapability.containsKey(nodeName)) {
            return basicChecks;
        }

        // We check that the node contains the special capability and if so, we try to match the capabilities
        if (nodeCapability.containsKey(nodeName)) {
            return basicChecks && nodeCapability.get(nodeName).equals(requestedCapability.get(nodeName));
        }

        // If none of the previous matched, the node does not have the capabilities
        return false;
    }
}
