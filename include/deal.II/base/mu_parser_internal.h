// ---------------------------------------------------------------------
//
// Copyright (C) 2005 - 2019 by the deal.II authors
//
// This file is part of the deal.II library.
//
// The deal.II library is free software; you can use it, redistribute
// it, and/or modify it under the terms of the GNU Lesser General
// Public License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
// The full text of the license can be found in the file LICENSE.md at
// the top level directory of deal.II.
//
// ---------------------------------------------------------------------

#ifndef dealii_mu_parser_internal_h
#define dealii_mu_parser_internal_h

// This file contains functions used internally by the FunctionParser
// and the TensorFunctionParser class.

#include <deal.II/base/config.h>

#include <string>
#include <vector>


DEAL_II_NAMESPACE_OPEN



#ifdef DEAL_II_WITH_MUPARSER

namespace internal
{
  namespace FunctionParser
  {
    /**
     * deal.II uses muParser as a purely internal dependency. To this end, we do
     * not include any muParser headers in our own headers (and the bundled
     * version of the dependency does not install its headers or compile a
     * separate muparser library). Hence, to interface with muParser, we use the
     * PIMPL idiom here to wrap a pointer to mu::Parser objects.
     */
    class muParserBase
    {
    public:
      virtual ~muParserBase() = default;
    };

    /**
     * Class containing the mutable state required by muParser.
     *
     * @note For performance reasons it is best to put all mutable state in a
     * single object so that, for each function call, we only need to get
     * thread-local data exactly once.
     */
    struct ParserData
    {
      /**
       * Default constructor. Threads::ThreadLocalStorage requires that objects
       * be either default- or copy-constructible: make sure we satisfy the
       * first case by declaring it here.
       */
      ParserData() = default;

      /**
       * std::is_copy_constructible gives the wrong answer for containers with
       * non-copy constructible types (e.g., std::vector<std::unique_ptr<int>>)
       * - for more information, see the documentation of
       * Threads::ThreadLocalStorage. Hence, to avoid compilation failures, just
       * delete the copy constructor completely.
       */
      ParserData(const ParserData &) = delete;

      /**
       * Scratch array used to set independent variables (i.e., x, y, and t)
       * before each muParser call.
       */
      std::vector<double> vars;

      /**
       * The actual muParser parser objects (hidden with PIMPL).
       */
      std::vector<std::unique_ptr<muParserBase>> parsers;
    };

    int
    mu_round(double val);

    double
    mu_if(double condition, double thenvalue, double elsevalue);

    double
    mu_or(double left, double right);

    double
    mu_and(double left, double right);

    double
    mu_int(double value);

    double
    mu_ceil(double value);

    double
    mu_floor(double value);

    double
    mu_cot(double value);

    double
    mu_csc(double value);

    double
    mu_sec(double value);

    double
    mu_log(double value);

    double
    mu_pow(double a, double b);

    double
    mu_erf(double value);

    double
    mu_erfc(double value);

    // returns a random value in the range [0,1] initializing the generator
    // with the given seed
    double
    mu_rand_seed(double seed);

    // returns a random value in the range [0,1]
    double
    mu_rand();

    /**
     * Get the array of all function names.
     */
    std::vector<std::string>
    get_function_names();

  } // namespace FunctionParser

} // namespace internal
#endif



DEAL_II_NAMESPACE_CLOSE

#endif
