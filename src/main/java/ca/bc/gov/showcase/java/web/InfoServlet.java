package ca.bc.gov.showcase.java.web;

import java.io.IOException;
import java.io.PrintWriter;
import java.net.InetAddress;
import java.net.UnknownHostException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * Servlet implementation class Info
 */
@WebServlet(urlPatterns= {"/info"}, loadOnStartup=1)
public class InfoServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
       
    /**
     * @see HttpServlet#HttpServlet()
     */
    public InfoServlet() {
        super();
        // TODO Auto-generated constructor stub
    }

    public static void write(HttpServletRequest request, PrintWriter writer) throws UnknownHostException {
		writer.append("URL: ").append(request.getRequestURL()).append('\n');
		writer.append("URI: ").append(request.getRequestURI()).append('\n');
		writer.append("Context Path: ").append(request.getContextPath()).append('\n');
		writer.append("Path Info: ").append(request.getPathInfo()).append('\n');
		writer.append("Protocol: ").append(request.getProtocol()).append('\n');
		InetAddress ip = InetAddress.getLocalHost();
		writer.append("Hostname: ").append(ip.getHostName()).append('\n');
		writer.append("IP: ").append(ip.getHostAddress()).append('\n');
		HttpSession session = request.getSession(false);
		if (session !=null) {
			writer.append("SessionId: ").append(session.getId()).append('\n');
		}else {
			writer.append("SessionId: ").append("-").append('\n');
		}
		
		if (request.getCookies()!=null) {
			for (Cookie c: request.getCookies()) {
				writer.append("Cookie["+c.getName()+"]: ").append(c.getValue()).append('\n');
			}
		}
		writer.flush();
    }
	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		response.setContentType("text/plain");
		PrintWriter writer = response.getWriter();
		write(request, writer);
	}

}
