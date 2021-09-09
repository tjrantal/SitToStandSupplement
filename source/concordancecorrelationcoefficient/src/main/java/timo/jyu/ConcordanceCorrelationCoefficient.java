package timo.jyu;
/*
	Implementation of concordance correlation coefficient
	http://en.wikipedia.org/wiki/Concordance_correlation_coefficient
	http://en.wikipedia.org/wiki/Pearson_product-moment_correlation_coefficient
	Correlation taken from apache commongs math 3.0 git clone http://git-wip-us.apache.org/repos/asf/commons-math.git
*/
import java.util.List;
import java.util.ArrayList;
public class ConcordanceCorrelationCoefficient{
	public double[] coefficients;
	double[] vec1;
	double[] vec2;
	public double anaDone;
	
	/**
		Calculate concordance correlation coefficient between input vectors sliding the second vector over all possible epochs in the first. First input should always be longer than the second
		@param vec1 vector one, should be longer than vector 2
		@param vec2 vector two, should be shorter than vector 1
	*/
	
	public ConcordanceCorrelationCoefficient(double[] vec1,double[] vec2){
		anaDone = 0d;
		List<Thread> threads = new ArrayList<Thread>();
		List<ConcRunnable> concRunnables = new ArrayList<ConcRunnable>();
		if (vec1.length > vec2.length){
			this.vec1 = vec1;
			this.vec2 = vec2;
		}else{
			this.vec2 = vec1;
			this.vec1 = vec2;
		}
		coefficients = new double[vec1.length-vec2.length+1];
		/*Create 4 threads for the calculation*/
		int[] inits = new int[]{0, coefficients.length/4, coefficients.length*2/4, coefficients.length*3/4};
		int[] ends = new int[]{inits[1], inits[2], inits[3], coefficients.length};
		for (int i = 0;i<inits.length;++i){
			concRunnables.add(new ConcRunnable(vec1,vec2,inits[i],ends[i]));
			threads.add(new Thread(concRunnables.get(i)));
			threads.get(i).start();
			//System.out.println("Started thread "+i);
		}
		//join threads
		for (int i = 0;i<threads.size();++i){
			try{
				((Thread) threads.get(i)).join();
			}catch(Exception er){}
			//System.out.println("Joined thread "+i);
			for (int j = concRunnables.get(i).init;j<concRunnables.get(i).end;++j){
				coefficients[j] = concRunnables.get(i).coeff[j];
			}
			//System.out.println("Got coeffs "+i);
		}
		anaDone = 1d;
		
	}
	public static double getDone(){
		double doneA = 12;
		return doneA;
	}
	
	
	public class ConcRunnable implements Runnable{
		public int init;
		public int end;
		double[] vect1;
		double[] tempV1;
		double[] vect2;
		public double[] coeff;
		public ConcRunnable(double[] vect1,double[] vect2,int init,int end){
			this.vect1 = vect1;
			this.vect2 = vect2;
			this.init = init;
			this.end = end;
			coeff = new double[vect1.length-vect2.length+1];
		}
		public void run(){
			coeff = concCorrCoeff(vect1,vect2,coeff,init,end);
		}
	}
	
	/**
		Calculate concordance correlation coefficient starting with varying indices of v1. v1.length > v2.length
		@param v1 vector one
		@param v2 vector two
		@param init initial index in v1 to start from
		@param end final index in v1 to calculate the coefficient for
		@return concordance correlation coefficients between v1, and v2
	*/
	public static double[] concCorrCoeff(double[] v1,double[] v2,double[] coeffs,int init, int end){
		int length = v2.length;
		/*Get initial values*/
		double var1 = variance(v1,init,length);
		double var2 = variance(v2);
		double meanv1 = mean(v1,init,length);
		double meanv2 = mean(v2);
		double sumtop = 0;
		double t1;
		double lengthScale = 1d/(double) length;
		double[] t2 = new double[length];
		for (int i = 0;i<length;++i){
			t1 = v1[i+init]-meanv1;
			t2[i] = v2[i]-meanv2;
			sumtop += t1*t2[i];
		}
		sumtop*=lengthScale;	//Normalise the covariance
		
		coeffs[init] = 2*sumtop/(var1+var2+Math.pow(meanv1-meanv2,2d));
		/*Update v1 values by taking of the first, and adding a new data point*/
		for (int i = init+1;i<end;++i){
			/*add next data point*/
			meanv1-=lengthScale*v1[i-1];	//remove the first data point
			meanv1+= lengthScale*(v1[i+length-1]);	//add the last
			
			/*Recalculate sumtop*/
			sumtop= 0;
			for (int j = 0; j<length;++j){
				t1 = v1[i+j]-meanv1;
				sumtop+=t1*t2[j];
			}
			sumtop*=lengthScale;	//Normalise the covariance
			var1 = variance(v1,i,length);	//Variance has to be recalculated as mean has changed
			coeffs[i] = 2*sumtop/(var1+var2+Math.pow(meanv1-meanv2,2d));
		}
		return coeffs;
	}
	
	/*
		Calculate mean
		@param data one dimensional array
		@return the mean of data
	*/
	public static double mean(double[] data){
		double sum = 0;
		for (int i = 0; i<data.length; ++i){
			sum+= data[i];
		}
		sum/=((double) data.length);
		return sum;
	}
	
	/*
		Calculate mean for a portion of a vector
		@param data one dimensional array
		@param init the index to start from
		@param length the length of the section to include
		@return the mean of data
	*/
	public static double mean(double[] data,int init, int length){
		double sum = 0;
		for (int i = init; i<init+length; ++i){
			sum+= data[i];
		}
		sum/=((double) length);
		return sum;
	}
	
	/*
		calculate variance
		@param data one dimensional array
		@return the variance of data
	*/
	public static double variance(double[] data){
		double variance = 0;
		double meanv = mean(data);
		double t;
		for (int i = 0; i<data.length; ++i){
			t = data[i]-meanv;
			variance+= t*t;
		}
		variance/=((double) data.length);
		return variance;
	}
	
	/*
		Calculate variance for a portion of a vector
		@param data one dimensional array
		@param init the index to start from
		@param length the length of the section to include
		@return the variance of data
	*/
	public static double variance(double[] data,int init, int length){
		double variance = 0;
		double meanv = mean(data,init,length);
		double t;
		for (int i = init; i<init+length; ++i){
			t = data[i]-meanv;
			variance+= t*t;
		}
		variance/=((double) length);
		return variance;
	}
}