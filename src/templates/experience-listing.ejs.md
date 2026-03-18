<%
for (item of items) {
  if (templateParams === undefined || !templateParams["resume-only"] || item.resume) {
%>
**<%= item.title %>**  (<%= item["start-date"]%>--<%= item["end-date"]%>)

*<%= item.workplace %>*

<%= item.description %>

<%
  }
}
%>

<!-- 
title: "Student Research Assistant",
workplace: "Georgia Institute of Technology",
"start-date": "2022/08",
"end-date": "2025/12",
description: "- Reduced subsurface CO~2~ estimation error by X% by applying ensemble Kalman filtering (EnKF) to surface seismic observations in realistic settings.\n" +
  "- Eliminated Gaussian instability in a scalable conditional neural normalizing flow by redesigning activation functions from first principles, enabling stable learning for both Gaussian and complex distributions.\n" +
  "- Published EnKF results in widely-cited, peer-reviewed IEEE TGRS journal.\n"
}, -->
