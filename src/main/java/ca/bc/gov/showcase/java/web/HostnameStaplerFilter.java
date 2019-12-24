package ca.bc.gov.showcase.java.web;

import java.io.IOException;
import java.net.InetAddress;
import java.net.UnknownHostException;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Servlet Filter implementation class HostnameStaplerFilter
 */
@WebFilter("/*")
public class HostnameStaplerFilter implements Filter {
	static final String hostname;
	static {
		try {
			hostname = InetAddress.getLocalHost().getHostName();
		} catch (UnknownHostException e) {
			throw new RuntimeException(e);
		}
	}
    /**
     * Default constructor. 
     */
    public HostnameStaplerFilter() {
        // TODO Auto-generated constructor stub
    	
    }

	/**
	 * @see Filter#destroy()
	 */
	public void destroy() {
		// TODO Auto-generated method stub
	}

	/**
	 * @see Filter#doFilter(ServletRequest, ServletResponse, FilterChain)
	 */
	public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
		Logger bam = LoggerFactory.getLogger("bam.wiof."+ this.getClass().getName());
		((HttpServletResponse)response).addHeader("Pod", hostname);
		bam.trace("Started");
		bam.debug("Started");
		bam.info("Started");
		bam.warn("Started");
		bam.error("Started");
		chain.doFilter(request, response);
		bam.error("Finished");
	}

	/**
	 * @see Filter#init(FilterConfig)
	 */
	public void init(FilterConfig fConfig) throws ServletException {
		// TODO Auto-generated method stub
	}

}
