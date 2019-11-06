<%@ page import="java.util.*" %>
<html>
<body>
<h2>Hello World!</h2>
<h2>HTTP Request Headers Received</h2>
<table>
    <% Enumeration enumeration = request.getHeaderNames(); while (enumeration.hasMoreElements()) { String name=(String) enumeration.nextElement(); String value = request.getHeader(name); %>
        <tr>
            <td>
                <%=name %>
            </td>
            <td>
                <%=value %>
            </td>
        </tr>
    <% } %>
</table>
</body>
</html>
